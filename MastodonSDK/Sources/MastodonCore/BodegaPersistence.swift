// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Bodega
import MastodonSDK
import Foundation

/// Cache user data in a local database.
///  MAKE SURE TO UPDATE removeUser() WHEN ADDING ADDITIONAL CACHES
public actor BodegaPersistence {
    private static func timelineStoreFilename(forUser user: UserIdentifier) -> String {
        return "Timeline-posts-\(user.globallyUniqueUserIdentifier)"
    }
    private static func timelineOrderFilename(forUser user: UserIdentifier) -> String {
        return "Timeline-order-\(user.globallyUniqueUserIdentifier)"
    }
    private static var _currentUserTimelineStore: (String, ObjectStorage<Mastodon.Entity.Status>)?
    
    private static let adminNotificationPreferenceStore = ObjectStorage<AdminNotificationFilterSettings>(storage:  SQLiteStorageEngine(directory: .documents(appendingPath: "AdminNotificationPreferences"))!)
    private static let lastReadMarkerStore = ObjectStorage<LastReadMarkers>(storage: SQLiteStorageEngine(directory: .documents(appendingPath: "LastReadMarkers"))!)
    
    private static let pushNotificationsPreferenceStore = ObjectStorage<PushNotificationsSubscription>(storage:  SQLiteStorageEngine(directory: .documents(appendingPath: "PushNotifications"))!)
    
    private static let recentLanguagesStore = ObjectStorage<[String]>(storage: SQLiteStorageEngine(directory: .documents(appendingPath: "RecentLanguages"))!)
        
//    private static var timelineCacheRequests = [(UserIdentifier, [TimelineItem])]()
//    private static var currentlyCaching: (UserIdentifier, [TimelineItem])?

    
    private static func homeTimelineItemStore(forUser user: UserIdentifier) -> ObjectStorage<Mastodon.Entity.Status>
    {
        if let _currentUserTimelineStore, _currentUserTimelineStore.0 == user.globallyUniqueUserIdentifier {
            return _currentUserTimelineStore.1
        } else {
            let storageEngine = SQLiteStorageEngine(directory: .forUser(user), databaseFilename: timelineStoreFilename(forUser: user))
            _currentUserTimelineStore = (user.globallyUniqueUserIdentifier, ObjectStorage<Mastodon.Entity.Status>(storage: storageEngine!))
        }
        return _currentUserTimelineStore!.1
    }

//    static func cachedTimeline(forUser user: UserIdentifier) -> [TimelineItem] {
//        guard let cachesDirectory = FileManager.default.cachesDirectory else { return [] }
//
//        let filePath = cachesDirectory.appendingPathComponent(timelineOrderFilename(forUser: user))
//
//        guard let data = try? Data(contentsOf: filePath) else { return [] }
//
//        do {
//            let cached = try JSONDecoder().decode([CacheableTimelineItem].self, from: data)
//            let timeline: [TimelineItem] = cached.compactMap {
//                switch $0 {
//                case .cachedPost(let info):
//                    let viewModel = MastodonPostViewModel(info, displayType: .standard)
//                    return .post(viewModel, isPinned: false)
//                case .missingPosts(let newerThan, let olderThan):
//                    return nil // loading results missing from the middle of a feed is no longer supported
//                }
//            }
//            return timeline
//        } catch {
//            return []
//        }
//    }
    
    public static func removeUser(_ userID: UserIdentifier) async throws {
        let cacheKey = CacheKey(userID.globallyUniqueUserIdentifier)
        try await adminNotificationPreferenceStore.removeObject(forKey: cacheKey)
        try await lastReadMarkerStore.removeObject(forKey: cacheKey)
//        try await clearCachedTimeline(forUser: userID)
        try await pushNotificationsPreferenceStore.removeObject(forKey: cacheKey)
        try await recentLanguagesStore.removeObject(forKey: cacheKey)
        if let _currentUserTimelineStore, _currentUserTimelineStore.0 == userID.globallyUniqueUserIdentifier {
            self._currentUserTimelineStore = nil
            Task {
                try FileManager.default.removeItem(at: FileManager.Directory.forUser(userID).url)
            }
        }
    }
    
    /// These are the account settings regarding notifications that appear in the notifications view
    public struct Notifications {
        public static func currentPreferences(for userID: UserIdentifier) async -> AdminNotificationFilterSettings? {
            return await adminNotificationPreferenceStore.object(forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
        
        public static func updatePreferences(_ preferences: AdminNotificationFilterSettings, for userID: UserIdentifier) async throws {
            try await adminNotificationPreferenceStore.store(preferences, forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
    }
    
    /// These are app-specific settings for which notifications also result in push notifications
    public struct PushNotifications {
        public static func activeSubscription(for userID: UserIdentifier) async -> PushNotificationsSubscription? {
            return await pushNotificationsPreferenceStore.object(forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
            
        public static func savePendingSubscriptionSettings(_ pendingSettings: PushNotificationsSubscription.PushNotificationsSettings, for authBox: MastodonAuthenticationBox) async throws {
            let activeSettings = await activeSubscription(for: authBox)?.current
            try await updateSubscription(PushNotificationsSubscription(current: activeSettings, pending: pendingSettings), for: authBox)
        }
        
        public static func didRegisterSubscription(_ subscription: Mastodon.Entity.Subscription, receiveFrom: Mastodon.API.Subscriptions.QueryData.Policy, for authBox: UserIdentifier) async throws {
            let newSettings = PushNotificationsSubscription.PushNotificationsSettings(pushNotificationsFrom: receiveFrom, mentions: subscription.alerts.mention, boosts: subscription.alerts.reblog, favorites: subscription.alerts.favourite, newFollowers: subscription.alerts.follow, followRequests: subscription.alerts.followRequest, polls: subscription.alerts.poll)
            
            let pendingSettings = await activeSubscription(for: authBox)?.pending

            let isEquivalentToPending: Bool = {
                guard let pendingSettings else { return true }
                return pendingSettings.pushNotificationsFrom == receiveFrom &&
                (pendingSettings.mentions == nil || pendingSettings.mentions == newSettings.mentions) &&
                (pendingSettings.boosts == nil || pendingSettings.boosts == newSettings.boosts) &&
                (pendingSettings.favorites == nil || pendingSettings.favorites == newSettings.favorites) &&
                (pendingSettings.newFollowers == nil || pendingSettings.newFollowers == newSettings.newFollowers) &&
                (pendingSettings.followRequests == nil || pendingSettings.newFollowers == newSettings.followRequests) &&
                (pendingSettings.polls == nil || pendingSettings.polls == newSettings.polls)
            }()
            try await updateSubscription(PushNotificationsSubscription(current: newSettings, pending: isEquivalentToPending ? nil : pendingSettings), for: authBox)
        }
        
        private static func updateSubscription(_ subscription: PushNotificationsSubscription, for userID: UserIdentifier) async throws {
            return try await pushNotificationsPreferenceStore.store(subscription, forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
    }
    
    public struct RecentLanguages {
        public static func recentLanguages(for userID: UserIdentifier) async -> [String]? {
            return await recentLanguagesStore.object(forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
        
        public static func updateRecentLanguages(_ languages: [String], for userID: UserIdentifier) async throws {
            return try await recentLanguagesStore.store(languages, forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
    }
    
    public struct LastRead {
        public static func lastReadMarkers(for userID: UserIdentifier) async -> LastReadMarkers? {
            return await lastReadMarkerStore.object(forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
        
        public static func saveLastReadMarkers(_ markers: LastReadMarkers, for userID: UserIdentifier) async throws {
            try await lastReadMarkerStore.store(markers, forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
    }
}

extension BodegaPersistence {
  
    
//    static func cacheTimeline(_ timeline: [TimelineItem], forUser user: UserIdentifier) {
//        var updatedQueue = timelineCacheRequests.filter { item in
//            return item.0.globallyUniqueUserIdentifier != user.globallyUniqueUserIdentifier
//        }
//        updatedQueue.append((user, timeline))
//        timelineCacheRequests = updatedQueue
//        doNextTimelineCacheIfReady()
//    }
//    
//    static func clearCachedTimeline(forUser user: UserIdentifier) async throws {
//        guard let cachesDirectory = FileManager.default.cachesDirectory else { return }
//        
//        // remove the list
//        let filePath = cachesDirectory.appendingPathComponent(timelineOrderFilename(forUser: user))
//        try FileManager.default.removeItem(at: filePath)
//        
//        // clear the posts
//        let itemStore = homeTimelineItemStore(forUser: user)
//        try await itemStore.removeAllObjects()
//    }
//    
//    private static func doNextTimelineCacheIfReady() {
//        guard currentlyCaching == nil, !timelineCacheRequests.isEmpty else { return }
//        
//        let next = timelineCacheRequests.removeFirst()
//        currentlyCaching = next
//        
//        Task {
//            try? await doCacheTimeline(next.1, forUser: next.0)
//            currentlyCaching = nil
//            doNextTimelineCacheIfReady()
//        }
//    }
//    
//    private static func doCacheTimeline(_ timeline: [TimelineItem], forUser user: UserIdentifier) async throws {
//        guard let cachesDirectory = FileManager.default.cachesDirectory else { return }
//        
//        // write the posts to the database
//        var posts = [(CacheKey, Mastodon.Entity.Status)]()
//        for item in timeline {
//            switch item {
//            case .collection, .heading, .loadingIndicator, .filteredNotificationsInfo, .hashtag, .account, .noItem:
//                break
//            case .pinnedPosts:
//                break  // this only occurs in user timelines for the profile views, and those are not cached
//            case .post(let viewModel, _):
//                if let fullPost = await viewModel.fullPost {
//                    posts.append((CacheKey(verbatim: fullPost.id), fullPost._legacyEntity))
//                }
//            case .notification:
//                // TODO: cache notifications?  Or give up on all caching.
//                break
//            }
//        }
//        
//        let itemStore = homeTimelineItemStore(forUser: user)
//        try await itemStore.store(posts)
//        
//        // write the order to the file
//        let writableTimeline: [CacheableTimelineItem] = timeline.compactMap { item in
//            switch item {
//            case .collection:
//                return nil
//            case .post(let viewModel, _):
//                return .cachedPost(viewModel.initialDisplayInfo)
//            case .pinnedPosts:
//                return nil // this only occurs in user timelines for the profile views, and those are not cached
//            case .heading, .loadingIndicator, .filteredNotificationsInfo, .account, .hashtag, .noItem:
//                return nil
//            case .notification:
//                // TODO: cache notifications? or give up on all caching?
//                return nil
//            }
//        }
//        
//        let filePath = cachesDirectory.appendingPathComponent(timelineOrderFilename(forUser: user))
//        let data = try JSONEncoder().encode(writableTimeline)
//        try data.write(to: filePath.standardizedFileURL)
//    }
}

//enum CacheableTimelineItem: Codable {
//    
//    case missingPosts(newerThan: Mastodon.Entity.Status.ID, olderThan: Mastodon.Entity.Status.ID)
//    case cachedPost(GenericMastodonPost.InitialDisplayInfo)
//    
//    enum CodingKeys: String, CodingKey {
//        case type
//        case initialDisplayInfo
//        case newerThan
//        case olderThan
//    }
//    
//    enum CaseType: String, Codable {
//        case post
//        case missingPosts
//    }
//    
//    func encode(to encoder: any Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        switch self {
//        case .missingPosts(let newerThan, let olderThan):
//            try container.encode(CaseType.missingPosts, forKey: .type)
//            try container.encode(newerThan, forKey: .newerThan)
//            try container.encode(olderThan, forKey: .olderThan)
//        case .cachedPost(let info):
//            try container.encode(CaseType.post, forKey: .type)
//            try container.encode(info, forKey: .initialDisplayInfo)
//        }
//    }
//    
//    init(from decoder: any Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        let type = try container.decode(CaseType.self, forKey: .type)
//        switch type {
//        case .missingPosts:
//            let newerThan = try container.decode(Mastodon.Entity.Status.ID.self, forKey: .newerThan)
//            let olderThan = try container.decode(Mastodon.Entity.Status.ID.self, forKey: .olderThan)
//            self = .missingPosts(newerThan: newerThan, olderThan: olderThan)
//        case .post:
//            let postInfo = try container.decode(GenericMastodonPost.InitialDisplayInfo.self, forKey: .initialDisplayInfo)
//            self = .cachedPost(postInfo)
//        }
//    }
//}

fileprivate extension FileManager.Directory {
    static func forUser(_ user: UserIdentifier) -> Self {
        return .documents(appendingPath: user.globallyUniqueUserIdentifier)
    }
}

public struct AdminNotificationFilterSettings: Codable, Equatable {
    public let forReports: Mastodon.Entity.NotificationPolicy.NotificationFilterAction
    public let forSignups: Mastodon.Entity.NotificationPolicy.NotificationFilterAction
    
    public var excludedNotificationTypes: [Mastodon.Entity.NotificationType]? {
        var excluded = [Mastodon.Entity.NotificationType]()
        if forReports != .accept {
            excluded.append(.adminReport)
        }
        if forSignups != .accept {
            excluded.append(.adminSignUp)
        }
        return excluded.isEmpty ? nil : excluded
    }
    
    public init(forReports: Mastodon.Entity.NotificationPolicy.NotificationFilterAction, forSignups: Mastodon.Entity.NotificationPolicy.NotificationFilterAction) {
        self.forReports = forReports
        self.forSignups = forSignups
    }
}
