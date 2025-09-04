// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Bodega
import MastodonCore
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
        
    private static var timelineCacheRequests = [(UserIdentifier, [TimelineItem])]()
    private static var currentlyCaching: (UserIdentifier, [TimelineItem])?

    
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

    static func cachedTimeline(forUser user: UserIdentifier) -> [TimelineItem] {
        guard let cachesDirectory = FileManager.default.cachesDirectory else { return [] }

        let filePath = cachesDirectory.appendingPathComponent(timelineOrderFilename(forUser: user))

        guard let data = try? Data(contentsOf: filePath) else { return [] }

        do {
            let cached = try JSONDecoder().decode([CacheableTimelineItem].self, from: data)
            let timeline: [TimelineItem] = cached.compactMap {
                switch $0 {
                case .cachedPost(let info):
                    let viewModel = MastodonPostViewModel(info, filterContext: .home, threadedConversationContext: nil)
                    return .post(viewModel)
                case .missingPosts(let newerThan, let olderThan):
                    return nil // loading results missing from the middle of a feed is no longer supported
                    break
                }
            }
            return timeline
        } catch {
            return []
        }
    }
    
    public static func removeUser(_ userID: UserIdentifier) async throws {
        let cacheKey = CacheKey(userID.globallyUniqueUserIdentifier)
        try await adminNotificationPreferenceStore.removeObject(forKey: cacheKey)
        try await lastReadMarkerStore.removeObject(forKey: cacheKey)
        try await clearCachedTimeline(forUser: userID)
        if let _currentUserTimelineStore, _currentUserTimelineStore.0 == userID.globallyUniqueUserIdentifier {
            self._currentUserTimelineStore = nil
            Task {
                try FileManager.default.removeItem(at: FileManager.Directory.forUser(userID).url)
            }
        }
    }
    
    public struct Notifications {
        static func currentPreferences(for userID: UserIdentifier) async -> AdminNotificationFilterSettings? {
            return await adminNotificationPreferenceStore.object(forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
        
        static func updatePreferences(_ preferences: AdminNotificationFilterSettings, for userID: UserIdentifier) async throws {
            try await adminNotificationPreferenceStore.store(preferences, forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
    }
    
    public struct LastRead {
        static func lastReadMarkers(for userID: UserIdentifier) async -> LastReadMarkers? {
            return await lastReadMarkerStore.object(forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
        
        static func saveLastReadMarkers(_ markers: LastReadMarkers, for userID: UserIdentifier) async throws {
            try await lastReadMarkerStore.store(markers, forKey: CacheKey(userID.globallyUniqueUserIdentifier))
        }
    }
}

extension BodegaPersistence {
    static func cachedPost(_ id: Mastodon.Entity.Status.ID, forUser user: UserIdentifier) async -> GenericMastodonPost? {
        guard let entity = await homeTimelineItemStore(forUser: user).object(forKey: CacheKey(verbatim: id)) else { return nil }
        return GenericMastodonPost.fromStatus(entity)
    }
    
    static func cachedPosts(_ ids: [Mastodon.Entity.Status.ID], forUser user: UserIdentifier) async -> [Mastodon.Entity.Status.ID : GenericMastodonPost] {
        let keys = ids.map { CacheKey(verbatim: $0) }
        let result = await homeTimelineItemStore(forUser: user).objectsAndKeys(keys: keys)
        return result.reduce(into: [Mastodon.Entity.Status.ID : GenericMastodonPost]()) { partialResult, element in
            partialResult[element.key.value] = GenericMastodonPost.fromStatus(element.object)
        }
    }
    
    static func cacheTimeline(_ timeline: [TimelineItem], forUser user: UserIdentifier) {
        var updatedQueue = timelineCacheRequests.filter { item in
            return item.0.globallyUniqueUserIdentifier != user.globallyUniqueUserIdentifier
        }
        updatedQueue.append((user, timeline))
        timelineCacheRequests = updatedQueue
        doNextTimelineCacheIfReady()
    }
    
    static func clearCachedTimeline(forUser user: UserIdentifier) async throws {
        guard let cachesDirectory = FileManager.default.cachesDirectory else { return }
        
        // remove the list
        let filePath = cachesDirectory.appendingPathComponent(timelineOrderFilename(forUser: user))
        try FileManager.default.removeItem(at: filePath)
        
        // clear the posts
        let itemStore = homeTimelineItemStore(forUser: user)
        try await itemStore.removeAllObjects()
    }
    
    private static func doNextTimelineCacheIfReady() {
        guard currentlyCaching == nil, !timelineCacheRequests.isEmpty else { return }
        
        let next = timelineCacheRequests.removeFirst()
        currentlyCaching = next
        
        Task {
            try? await doCacheTimeline(next.1, forUser: next.0)
            currentlyCaching = nil
            doNextTimelineCacheIfReady()
        }
    }
    
    private static func doCacheTimeline(_ timeline: [TimelineItem], forUser user: UserIdentifier) async throws {
        guard let cachesDirectory = FileManager.default.cachesDirectory else { return }
        
        // write the posts to the database
        var posts = [(CacheKey, Mastodon.Entity.Status)]()
        for item in timeline {
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo:
                break
            case .post(let viewModel):
                if let fullPost = await viewModel.fullPost {
                    posts.append((CacheKey(verbatim: fullPost.id), fullPost._legacyEntity))
                }
            case .notification:
                // TODO: cache notifications?  Or give up on all caching.
                break
            }
        }
        
        let itemStore = homeTimelineItemStore(forUser: user)
        try await itemStore.store(posts)
        
        // write the order to the file
        let writableTimeline: [CacheableTimelineItem] = timeline.compactMap { item in
            switch item {
            case .post(let viewModel):
                return .cachedPost(viewModel.initialDisplayInfo)
            case .loadingIndicator, .filteredNotificationsInfo:
                return nil
            case .notification:
                // TODO: cache notifications? or give up on all caching?
                return nil
            }
        }
        
        let filePath = cachesDirectory.appendingPathComponent(timelineOrderFilename(forUser: user))
        let data = try JSONEncoder().encode(writableTimeline)
        try data.write(to: filePath.standardizedFileURL)
    }
}

enum CacheableTimelineItem: Codable {
    
    case missingPosts(newerThan: Mastodon.Entity.Status.ID, olderThan: Mastodon.Entity.Status.ID)
    case cachedPost(GenericMastodonPost.InitialDisplayInfo)
    
    enum CodingKeys: String, CodingKey {
        case type
        case initialDisplayInfo
        case newerThan
        case olderThan
    }
    
    enum CaseType: String, Codable {
        case post
        case missingPosts
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .missingPosts(let newerThan, let olderThan):
            try container.encode(CaseType.missingPosts, forKey: .type)
            try container.encode(newerThan, forKey: .newerThan)
            try container.encode(olderThan, forKey: .olderThan)
        case .cachedPost(let info):
            try container.encode(CaseType.post, forKey: .type)
            try container.encode(info, forKey: .initialDisplayInfo)
        }
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CaseType.self, forKey: .type)
        switch type {
        case .missingPosts:
            let newerThan = try container.decode(Mastodon.Entity.Status.ID.self, forKey: .newerThan)
            let olderThan = try container.decode(Mastodon.Entity.Status.ID.self, forKey: .olderThan)
            self = .missingPosts(newerThan: newerThan, olderThan: olderThan)
        case .post:
            let postInfo = try container.decode(GenericMastodonPost.InitialDisplayInfo.self, forKey: .initialDisplayInfo)
            self = .cachedPost(postInfo)
        }
    }
}

fileprivate extension FileManager.Directory {
    static func forUser(_ user: UserIdentifier) -> Self {
        return .documents(appendingPath: user.globallyUniqueUserIdentifier)
    }
}
