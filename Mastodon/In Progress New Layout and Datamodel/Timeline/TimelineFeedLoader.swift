// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonCore
import MastodonSDK

public enum NotificationsScope: Hashable {
    case everything
    case mentions
    case fromRequest(Mastodon.Entity.NotificationRequest)

//    var title: String {
//        switch self {
//        case .everything:
//            return L10n.Scene.Notification.Title.everything
//        case .mentions:
//            return L10n.Scene.Notification.Title.mentions
//        case .fromAccount(let account):
//            return "Notifications from \(account.displayName)"
//        }
//    }
    
//    var feedKind: MastodonFeedKind {
//        switch self {
//        case .everything:
//            return .notificationsAll
//        case .mentions:
//            return .notificationsMentionsOnly
//        case .fromAccount(let account):
//            return .notificationsWithAccount(account.id)
//        }
//    }
}

public enum MastodonTimelineType: Equatable {
    case following
    case myBookmarks
    case myFavorites
    case local
    case list(String)
    case hashtag(String)
    case discovery
    case search(String)
    case userPosts(userID: String, queryFilter: TimelineQueryFilter)
    case thread(root: MastodonContentPost)
    case remoteThread(remoteType: RemoteThreadType)
    case notifications(scope: NotificationsScope)

    public static func == (lhs: MastodonTimelineType, rhs: MastodonTimelineType) -> Bool {
        switch (lhs, rhs) {
        case (.following, .following): return true
        case (.local, .local): return true
        case (.list(let first), .list(let second)): return first == second
        case (.hashtag(let first), .hashtag(let second)): return first == second
        case (.discovery, .discovery): return true
        case (.search(let first), .search(let second)): return first == second
        case (.userPosts(let firstID, let firstFilter), .userPosts(let secondID, let secondFilter)): return firstID == secondID && firstFilter == secondFilter
        case (.thread(let first), .thread(let second)): return first.id == second.id
        case (.notifications(let firstScope), .notifications(let secondScope)): return firstScope == secondScope
        default: return false
        }
    }
    
    public var canDisplayFilteredNotifications: Bool {
        switch self {
        case .notifications(.everything), .notifications(.mentions):
            return true
        default:
            return false
        }
    }
    
    public var canDisplayUnreadNotifications: Bool {
        switch self {
        case .notifications(.everything), .notifications(.mentions):
            return true
        default:
            return false
        }
    }
    
    public var canDisplayDonationBanner: Bool {
        switch self {
        case .following:
            return true
        default:
            return false
        }
    }
}

public struct TimelineQueryFilter: Equatable {
    let excludeReplies: Bool?
    let excludeReblogs: Bool?
    let onlyMedia: Bool?
    
    init(
        excludeReplies: Bool? = nil,
        excludeReblogs: Bool? = nil,
        onlyMedia: Bool? = nil
    ) {
        self.excludeReplies = excludeReplies
        self.excludeReblogs = excludeReblogs
        self.onlyMedia = onlyMedia
    }
}

extension GenericMastodonPost {
    struct InitialDisplayInfo: Codable {
        let id: Mastodon.Entity.Status.ID
        let actionablePostID: Mastodon.Entity.Status.ID
        let shouldFilterOut: Bool
        let actionableAuthorId: String
        let actionableAuthorStaticAvatar: URL?
        let actionableAuthorHandle: String
        let actionableAuthorDisplayName: String
        let actionableVisibility: GenericMastodonPost.PrivacyLevel
        let actionableCreatedAt: Date
    }
}

enum TimelineItem: Identifiable {
    case post(MastodonPostViewModel)
    case notification(NotificationRowViewModel)
    case filteredNotificationsInfo(
        Mastodon.Entity.NotificationPolicy?,
        FilteredNotificationsRowView.ViewModel?)
    case loadingIndicator
    
    var id: String {
        switch self {
        case .post(let postViewModel):
            return postViewModel.initialDisplayInfo.id
        case .notification(let groupedNotificationInfo):
            return groupedNotificationInfo.id
        case .filteredNotificationsInfo:
            return "filteredNotifications"
        case .loadingIndicator:
            return "loading..."
        }
    }
    
    var isRealItem: Bool {
        switch self {
        case .post, .notification:
            return true
        case .filteredNotificationsInfo, .loadingIndicator:
            return false
        }
    }
}

extension TimelineItem: Equatable {
    static func == (lhs: TimelineItem, rhs: TimelineItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension TimelineItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

fileprivate let relationshipStaleThreshold: TimeInterval = 20 /*min*/ * 60 /*sec*/

#if DEBUG
public var recentlyInsertedItemIds: Set<String>?
#endif

@MainActor
final class TimelineFeedLoader: MastodonFeedLoader<TimelineItem, CacheableTimeline> {
#if DEBUG
    private var _createArtificialGapForTesting = false
#endif
    
    private let filterContext: Mastodon.Entity.FilterContext?
    
    private let authenticatedUser: MastodonAuthenticationBox
    private var cachedRelationships = [Mastodon.Entity.Account.ID : MastodonAccount.Relationship]()
    private var accountsCache = [Mastodon.Entity.Account.ID : MastodonAccount]()
    private var contentConcealViewModels = [Mastodon.Entity.Status.ID : ContentConcealViewModel]()
    private var postViewModels = [Mastodon.Entity.Status.ID : MastodonPostViewModel]()
    private var notificationViewModels = [Mastodon.Entity.NotificationGroup.ID : NotificationRowViewModel]()
    
    private let myAccountID: Mastodon.Entity.Account.ID?
    
    let timeline: MastodonTimelineType
    var threadedConversationModel: ThreadedConversationModel?
    
    init(currentUser: MastodonAuthenticationBox, timeline: MastodonTimelineType) {
        self.timeline = timeline
        authenticatedUser = currentUser
        myAccountID = authenticatedUser.cachedAccount?.id
        let trackLastRead = timeline == .following
        let cacheManager = TimelineCacheManager(currentUser: currentUser, trackLastRead: trackLastRead, useDiskCache: false)
        
        switch timeline {
        case .following:
            self.filterContext = .home
        case .hashtag:
            self.filterContext = .public
        case .list:
            self.filterContext = .home
        case .local:
            self.filterContext = .public
        case .discovery:
            self.filterContext = .public
        case .search(_):
            self.filterContext = nil
        case .userPosts:
            self.filterContext = .account
        case .thread, .remoteThread:
            self.filterContext = .account
        case .myBookmarks:
            self.filterContext = nil
        case .myFavorites:
            self.filterContext = nil
        case .notifications:
            self.filterContext = .notifications
        }
        super.init(cacheManager)
    }

    override func fetchResults(for request: MastodonFeedLoaderRequest) async throws -> CacheableTimeline {
        
        await AuthenticationServiceProvider.shared.fetchAccounts(onlyIfItHasBeenAwhile: true) // TODO: legacy comments indicated this may not be the best place for this call
        
        let itemsNoOlderThan: String?
        let itemsImmediatelyBefore: String?
        let itemsImmediatelyAfter: String?
        let fetchOffset: Int?
        
        switch request {
        case .newer:
            let mostRecentID = {
                switch records.allRecords.count {
                case 0, 1:
                    return records.allRecords.first?.id
                default:
                    return records.allRecords[1].id  // we want to allow the possibility of an overlap in order to detect gaps
                }
            }()
            itemsNoOlderThan = mostRecentID
            itemsImmediatelyBefore = nil
            itemsImmediatelyAfter = nil
            fetchOffset = nil
        case .older:
            let olderThan = {
                let count = records.allRecords.count
                switch count {
                case 0, 1:
                    return records.allRecords.last?.id
                default:
                    return records.allRecords[count - 2].id  // we want to allow the possibility of an overlap in order to detect gaps
                }
            }()
            itemsImmediatelyBefore = olderThan
            itemsNoOlderThan = nil
            itemsImmediatelyAfter = nil
            fetchOffset = max(0, records.allRecords.count - 1)  // -1 for overlap so the previous items don't get thrown out
        case .reload:
            itemsNoOlderThan = nil
            itemsImmediatelyBefore = nil
            itemsImmediatelyAfter = nil
            fetchOffset = nil
        case .newerThan(let id):
            itemsImmediatelyAfter = id
            itemsImmediatelyBefore = nil
            itemsNoOlderThan = nil
            fetchOffset = nil
        case .olderThan(let id):
            itemsImmediatelyBefore = id
            itemsImmediatelyAfter = nil
            itemsNoOlderThan = nil
            fetchOffset = nil
        }
        
        
        var newPostModels = [Mastodon.Entity.Status.ID : MastodonPostViewModel]()
        var newNotificationModels = [Mastodon.Entity.NotificationGroup.ID : NotificationRowViewModel]()
        
        func timelineItem(fromStatus status: Mastodon.Entity.Status) -> TimelineItem {
            let post = GenericMastodonPost.fromStatus(status)
            return timelineItem(fromPost: post)
        }
        func timelineItem(fromPost post: GenericMastodonPost) -> TimelineItem {
            let initialDisplayInfo = post.initialDisplayInfo(inContext: filterContext)
            let viewModel = postViewModels[initialDisplayInfo.id] ?? MastodonPostViewModel(initialDisplayInfo, filterContext: filterContext, threadedConversationContext: threadedConversationModel?.context(for: initialDisplayInfo.id))
            newPostModels[initialDisplayInfo.id] = viewModel
            viewModel.setFullPost(post)
            return TimelineItem.post(viewModel)
        }

        let newBatch: [TimelineItem]
        switch timeline {
        case .following:
            newBatch = try await APIService.shared.homeTimeline(itemsNoOlderThan: itemsNoOlderThan, itemsImmediatelyAfter: itemsImmediatelyAfter, itemsImmediatelyBefore: itemsImmediatelyBefore, authenticationBox: authenticatedUser).value.map { timelineItem(fromStatus:$0) }
        case .local:
            newBatch = try await APIService.shared.publicTimeline(
                query: .init(local: true, maxID: itemsImmediatelyBefore, sinceID: itemsNoOlderThan, minID: itemsImmediatelyAfter),
                authenticationBox: authenticatedUser
            ).value.map { timelineItem(fromStatus: $0) }
        case .list(let listId):
            newBatch = try await APIService.shared.listTimeline(
                id: listId,
                query: .init(local: true, maxID: itemsImmediatelyBefore, sinceID: itemsNoOlderThan, minID: itemsImmediatelyAfter),
                authenticationBox: authenticatedUser
            ).value.map { timelineItem(fromStatus: $0) }
        case .hashtag(let hashtag):
            newBatch = try await APIService.shared.hashtagTimeline(
                sinceID: itemsNoOlderThan,
                maxID: itemsImmediatelyBefore,
                hashtag: hashtag,
                authenticationBox: authenticatedUser
            ).value.map { timelineItem(fromStatus: $0) }
        case .discovery:
            newBatch = try await APIService.shared.trendStatuses(
                domain: authenticatedUser.domain,
                query: Mastodon.API.Trends.StatusQuery(
                    offset: fetchOffset,
                    limit: nil
                ),
                authenticationBox: authenticatedUser
            ).value.map { timelineItem(fromStatus: $0) }
        case .search(let searchText):
            let query = Mastodon.API.V2.Search.Query(
                q: searchText,
                type: .statuses,
                accountID: nil,
                maxID: nil,
                minID: nil,
                excludeUnreviewed: nil,
                resolve: true,
                limit: nil,
                offset: fetchOffset,
                following: nil
            )
            newBatch = try await APIService.shared.search(
                        query: query,
                        authenticationBox: authenticatedUser
            ).value.statuses.map { timelineItem(fromStatus: $0) }
        case .userPosts(let userID, let queryFilter):
            newBatch = try await APIService.shared.userTimeline(
                accountID: userID,
                maxID: itemsImmediatelyBefore,
                sinceID: nil,
                excludeReplies: queryFilter.excludeReplies,
                excludeReblogs: queryFilter.excludeReblogs,
                onlyMedia: queryFilter.onlyMedia,
                authenticationBox: authenticatedUser
            ).value.map { timelineItem(fromStatus: $0) }
        case .remoteThread(let remoteThreadType):
            let status: Mastodon.Entity.Status
            switch remoteThreadType {
            case .status(let statusID):
                status = try await APIService.shared.status(statusID: statusID, authenticationBox: authenticatedUser).value
            case .notification(let notificationID):
                let notification = try await APIService.shared.notification(notificationID: notificationID, authenticationBox: authenticatedUser).value
                guard notification.status != nil else { throw APIService.APIError.explicit(.badResponse) }
                status = notification.status!
            }
            let post = GenericMastodonPost.fromStatus(status)
            let context = try await APIService.shared.statusContext(
                statusID: status.id,
                authenticationBox: authenticatedUser
            ).value
            let threadModel = ThreadedConversationModel(threadContext: context, focusedPost: post)
            threadedConversationModel = threadModel
                newBatch = threadModel.fullThread.map { timelineItem(fromStatus: $0) }
        case .thread(let root):
            let context = try await APIService.shared.statusContext(
                statusID: root.id,
                authenticationBox: authenticatedUser
            ).value
            let threadModel: ThreadedConversationModel
            if let basicPost = root as? MastodonBasicPost, let quote = basicPost.quotedPost, quote.fullPost == nil, quote.quotedPostID != nil {
                // likely this is a nested quote that is now being opened and therefore we should refetch the status in hopes of getting the full quoted status to display instead of the placeholder
                let refetchedStatus = try await APIService.shared.status(statusID: root.id, authenticationBox: authenticatedUser).value
                threadModel = ThreadedConversationModel(threadContext: context, focusedPost: GenericMastodonPost.fromStatus(refetchedStatus))
            } else {
                threadModel = ThreadedConversationModel(threadContext: context, focusedPost: root)
            }
            threadedConversationModel = threadModel
            newBatch = threadModel.fullThread.map { timelineItem(fromStatus: $0) }
        case .myBookmarks:
            newBatch = try await APIService.shared.bookmarkedStatuses(
                maxID: itemsImmediatelyBefore,
                authenticationBox: authenticatedUser
            ).value.map { timelineItem(fromStatus: $0) }
        case .myFavorites:
            newBatch = try await APIService.shared.favoritedStatuses(
                maxID: itemsImmediatelyBefore,
                authenticationBox: authenticatedUser
            ).value.map { timelineItem(fromStatus: $0) }
        case .notifications(scope: let scope):
            print("loading notifications request \(request)")
            newBatch = try await NotificationsLoader.getNotifications(withScope: scope, olderThan: itemsImmediatelyAfter, newerThan: itemsImmediatelyBefore).map { groupedNotificationInfo in
                if groupedNotificationInfo.groupedNotificationType.wantsFullStatusLayout, let post = groupedNotificationInfo.post {
                    return timelineItem(fromPost: post)
                } else {
                    let notificationViewModel = notificationViewModels[groupedNotificationInfo.id] ?? NotificationRowViewModel(groupedNotificationInfo, myAccountDomain: authenticatedUser.domain)
                    if notificationViewModels[groupedNotificationInfo.id] != nil {
                        notificationViewModel.update(from: groupedNotificationInfo)
                    }
                    newNotificationModels[groupedNotificationInfo.id] = notificationViewModel
                    return TimelineItem.notification(notificationViewModel)
                }
            }
        }
        
        let newCache: CacheableTimeline
#if DEBUG && false
        let associatedPolls = polls(response)
        if _createArtificialGapForTesting {
            _createArtificialGapForTesting = false
            let testingOldID = "" // insert useful postid for your purposes here
            let older = try await APIService.shared.homeTimeline(itemsImmediatelyBefore: testingOldID, authenticationBox: authenticatedUser)
            let oldBatch = older.value.map { status in
                let post = GenericMastodonPost.fromStatus(status)
                return TimelineItem.post(post)
            }
            let associatedPollsPlus = polls(older.value, addedTo: associatedPolls)
            newCache = CacheableTimeline(older: oldBatch, newer: newBatch)
        } else {
            newCache = CacheableTimeline(older: [], newer: newBatch)
        }
#else
        newCache = CacheableTimeline(older: [], newer: newBatch)
#endif

        postViewModels = newPostModels
        notificationViewModels = newNotificationModels
        createContentConcealViewModels(newCache)
        try? await fetchReplyTos(newCache)
        
        return newCache
    }
    
    override func filteredResults(fromCachedType cached: CacheableTimeline) -> [TimelineItem] {
        cached.filteredItems(inContext: filterContext)
    }
    
}

extension TimelineFeedLoader {
    func fetchCachedPosts(_ postIds: [Mastodon.Entity.Status.ID]) async -> [Mastodon.Entity.Status.ID : GenericMastodonPost] {
        return await BodegaPersistence.cachedPosts(postIds, forUser: authenticatedUser)
    }
}

extension TimelineFeedLoader {
    func saveLastRead(_ id: Mastodon.Entity.Status.ID) {
        cacheManager.updateToNewerMarker(.local(lastReadID: id), enforceForwardProgress: false)
    }
}

private func polls(_ statuses: [Mastodon.Entity.Status], addedTo existing: [Mastodon.Entity.Poll.ID : Mastodon.Entity.Poll]? = nil) -> [Mastodon.Entity.Poll.ID : Mastodon.Entity.Poll] {
    let starter = existing ?? [Mastodon.Entity.Poll.ID : Mastodon.Entity.Poll]()
    return statuses.reduce(into: starter, { partialResult, status in
        if let poll = status.poll ?? status.reblog?.poll {
            partialResult[poll.id] = poll
        }
    })
}

struct CacheableTimeline: CacheableFeed {
    
    let items: [TimelineItem]
    
    @MainActor
    func filteredItems(inContext context: Mastodon.Entity.FilterContext?) -> [TimelineItem] {
        return items.filter { item in
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo:
                return true
            case .post(let postViewModel):
                if let contentPost = postViewModel.fullPost as? MastodonContentPost {
                    return !contentPost.content.shouldBeRemovedFromFeed(inContext: context)
                } else if let boost = postViewModel.fullPost as? MastodonBoostPost {
                    return !boost.boostedPost.content.shouldBeRemovedFromFeed(inContext: context)
                } else {
                    return !postViewModel.initialDisplayInfo.shouldFilterOut
                }
            case .notification(let groupedInfo):
                // TODO: filter based on contained statuses
                return true
            }
        }
    }
    
    var hasResults: Bool {
        return !items.isEmpty
    }
 
    init(older: [TimelineItem], newer: [TimelineItem]) {
        
        var combined: [TimelineItem]
        
        let oldestIdInNewBatch = newer.last(where: { item in
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo: return false
            case .post: return true
            case .notification: return true
            }
        })?.id
        
        if let oldestIdInNewBatch {
            let overlapIndex = older.firstIndex(where: { item in
                switch item {
                case .post:
                    return item.id == oldestIdInNewBatch
                case .notification:
                    return item.id == oldestIdInNewBatch
                case .loadingIndicator, .filteredNotificationsInfo:
                    return false
                }
            })
            if let overlapIndex {
                let firstOlderIndexToRetain = overlapIndex + 1
                if firstOlderIndexToRetain < older.count {
                    let olderTail = older.suffix(from: firstOlderIndexToRetain)
                    combined = newer + olderTail
                } else {
                    combined = newer
                }
            } else {
                combined = newer  // do not allow gaps
            }
        } else {
            assert(newer.isEmpty, "How else did we get here?")
            combined = older
        }
        
        items = combined
    }

    @MainActor
    func update(fromPost updated: GenericMastodonPost) {
        for item in items {
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo:
                break
            case .post(let existingViewModel):
                do {
                    try existingViewModel.update(from: updated)
                } catch {}
                do {
                    try existingViewModel.fullQuotedPostViewModel?.update(from: updated)
                } catch {}
            case .notification(let notificationViewModel):
                guard let embeddedPostModel = notificationViewModel.inlinePostViewModel else { break }
                do {
                    try embeddedPostModel.update(from: updated)
                } catch {}
                do {
                    try embeddedPostModel.fullQuotedPostViewModel?.update(from: updated)
                } catch {}
            }
        }
    }
    
    @MainActor
    func byDeleting(postId: Mastodon.Entity.Status.ID) -> CacheableTimeline {
        let newItems = items.filter { item in
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo:
                return true
            case .post(let postViewModel):
                return postViewModel.fullPost?.actionablePost?.id != postId
            case .notification:
                // TODO: anything?
                return true
            }
        }
        
        return CacheableTimeline(older: [], newer: newItems)
    }
}

@MainActor
class TimelineCacheManager: MastodonFeedCacheManager {
    typealias CachedType = CacheableTimeline
    
    private let currentUser: MastodonAuthenticationBox
    private let useDiskCache: Bool
    
    init(currentUser: MastodonAuthenticationBox, trackLastRead: Bool, useDiskCache: Bool) {
        self.currentUser = currentUser
        self.trackLastRead = trackLastRead
        self.useDiskCache = useDiskCache
        
        if useDiskCache {
            Task {
                let timeline = BodegaPersistence.cachedTimeline(forUser: currentUser)
                if trackLastRead {
                    self.currentLastReadMarker = await BodegaPersistence.LastRead.lastReadMarkers(for: currentUser)?.lastRead(forKind: .home)
                }
                self.staleResults = CacheableTimeline(older: [], newer: timeline)
            }
        }
    }
    
    func currentResults() -> CacheableTimeline? {
        if let mostRecentlyFetchedResults {
            return mostRecentlyFetchedResults
        } else if let staleResults {
            return staleResults
        }
        return nil
    }
    
    private var staleResults: CacheableTimeline?
    var mostRecentlyFetchedResults: CacheableTimeline?
    
    func updateByInserting(newlyFetched: CacheableTimeline, at insertionPoint: MastodonFeedLoaderRequest.InsertLocation) {
        switch insertionPoint {
        case .start:
            mostRecentlyFetchedResults = CacheableTimeline(older: currentResults()?.items ?? [], newer: newlyFetched.items)
        case .end:
            mostRecentlyFetchedResults = CacheableTimeline(older: newlyFetched.items, newer: currentResults()?.items ?? [])
        case .replace:
            mostRecentlyFetchedResults = newlyFetched
        case .asOlderThan(let id):
            assertionFailure("loading results missing from the middle of a feed is no longer supported")
            break
        case .asNewerThan(let id):
            assertionFailure("loading results missing from the middle of a feed is no longer supported")
            break
        }
    }
    
    let trackLastRead: Bool
    var currentLastReadMarker: LastReadMarkers.MarkerPosition?
    
    func didFetchMarkers(_ updatedMarkers: MastodonSDK.Mastodon.Entity.Marker) {
        // TODO: implement
    }
    
    func updateToNewerMarker(_ newMarker: LastReadMarkers.MarkerPosition, enforceForwardProgress: Bool) {
        guard trackLastRead else { return }
        currentLastReadMarker = newMarker
        Task {
            await commitToCache()
        }
    }
    
    func commitToCache() async {
        guard useDiskCache else { return }
        if let items = currentResults()?.items {
            BodegaPersistence.cacheTimeline(items, forUser: currentUser)
            guard trackLastRead, let currentLastReadMarker else { return }
            Task {
                let currentMarkers = await BodegaPersistence.LastRead.lastReadMarkers(for: currentUser) ?? LastReadMarkers(userGUID: currentUser.globallyUniqueUserIdentifier, home: nil, notifications: nil, mentions: nil)
                try await BodegaPersistence.LastRead.saveLastReadMarkers(currentMarkers.bySettingPosition(currentLastReadMarker, forKind: .home, enforceForwardProgress: false), for: currentUser)
            }
        }
    }
    
    func clearCache() async {
        guard useDiskCache else { return }
        try? await BodegaPersistence.clearCachedTimeline(forUser: currentUser)
    }
}

extension GenericMastodonPost.PostContent {
    func shouldBeRemovedFromFeed(inContext context: Mastodon.Entity.FilterContext?) -> Bool {
        guard let context else { return false }
        guard let filterResults = filtered else { return false }
        for result in filterResults {
            if result.filter.filterAction == .hide {
                for filterContext in result.filter.context {
                    if filterContext == context {
                        return true
                    }
                }
            }
        }
        return false
    }
}

// MARK: Update Posts
extension TimelineFeedLoader {
    func updatePost(post: GenericMastodonPost) {
        updateCachedResults { cached in
            cached.update(fromPost: post)
        }
    }
    
    func didDeletePost(_ postID: Mastodon.Entity.Status.ID) {
        transformCachedResults { cached in
            return cached.byDeleting(postId: postID)
        }
    }
}

// MARK: Relationships
extension TimelineFeedLoader {
    func myRelationship(to accountID: Mastodon.Entity.Account.ID) -> MastodonAccount.Relationship {
        if accountID == myAccountID {
            return .isMe
        } else {
            return cachedRelationships[accountID] ?? .isNotMe(nil)
        }
    }
    
    func updateMyRelationship(_ relationship: MastodonAccount.Relationship, to accountID: Mastodon.Entity.Account.ID) {
        cachedRelationships[accountID] = relationship
    }
    
    func fetchRelationships(_ batch: [Mastodon.Entity.Account.ID]) async throws -> [MastodonAccount.Relationship] {
        guard !batch.isEmpty else { return [] }
        
        let chunkSize = 100
        var relationships = [Mastodon.Entity.Relationship]()
        for start in stride(from: 0, to: batch.count, by: chunkSize) { // asking for too many at once can cause an API error
            let end = min(start + chunkSize, batch.count)
            let chunk = Array(batch[start..<end])
            let chunkResults = try await APIService.shared.relationship(forAccountIds: chunk, authenticationBox: authenticatedUser).value
            relationships.append(contentsOf: chunkResults)
        }
        
        let currentTimestamp = Date.now
        for relationshipEntity in relationships {
            cachedRelationships[relationshipEntity.id] = MastodonAccount.Relationship.isNotMe(MastodonAccount.RelationshipInfo(relationshipEntity, fetchedAt: currentTimestamp))
        }
        
        return relationships.map { relationshipEntity in
            MastodonAccount.Relationship.isNotMe(MastodonAccount.RelationshipInfo(relationshipEntity, fetchedAt: currentTimestamp))
        }
    }
}

// MARK: Accounts Cache
extension TimelineFeedLoader {
    func account(_ id: Mastodon.Entity.Account.ID) -> MastodonAccount? {
        return accountsCache[id]
    }
    
    private func fetchReplyTos(_ timeline: CacheableTimeline) async throws {
        let accountsToFetch = timeline.items.compactMap { item in
            switch item {
            case .post(let postViewModel):
                return (postViewModel.fullPost as? MastodonBasicPost)?.inReplyTo?.accountID
            default:
                return nil
            }
        }
        
        let accounts = try await APIService.shared.accountsInfo(userIDs: accountsToFetch, authenticationBox: authenticatedUser)
        
        accountsCache.removeAll(keepingCapacity: true)
        for account in accounts {
            accountsCache[account.id] = MastodonAccount.fromEntity(account)
        }
    }
}

// MARK: Filters and Content Warnings
extension TimelineFeedLoader {
    private func createContentConcealViewModels(_ cache: CacheableTimeline) {
        for item in cache.items {
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo:
                break
            case .post(let postViewModel):
                if let contentPost = postViewModel.fullPost?.actionablePost, contentConcealViewModels[contentPost.id] == nil {
                    contentConcealViewModels[contentPost.id] = ContentConcealViewModel(contentPost: contentPost, context: filterContext)
                }
            case .notification:
                // TODO: create conceal models for summarized statuses?
                break
            }
        }
    }
    
    public func contentConcealViewModel(forContentPost contentPost: Mastodon.Entity.Status.ID?) -> ContentConcealViewModel? {
        guard let contentPost else { return nil }
        return contentConcealViewModels[contentPost]
    }
}

extension GenericMastodonPost {
    func initialDisplayInfo(inContext context: Mastodon.Entity.FilterContext?) -> GenericMastodonPost.InitialDisplayInfo {
        let author = actionablePost?.metaData.author ?? metaData.author
        return GenericMastodonPost.InitialDisplayInfo(id: id, actionablePostID: actionablePost?.id ?? id, shouldFilterOut: actionablePost?.content.shouldBeRemovedFromFeed(inContext: context) ?? false, actionableAuthorId: author.id, actionableAuthorStaticAvatar: author.displayInfo.avatarUrl, actionableAuthorHandle: author.handle, actionableAuthorDisplayName: author.displayName(whenViewedBy: nil)?.plainString ?? "", actionableVisibility: actionablePost?.metaData.privacyLevel ?? metaData.privacyLevel ?? .loudPublic, actionableCreatedAt: actionablePost?.metaData.createdAt ?? metaData.createdAt)
    }
}

@MainActor
struct NotificationsLoader {
    
    static func getNotifications(withScope scope: NotificationsScope, olderThan: String? = nil, newerThan: String?) async throws -> [GroupedNotificationInfo] {
        guard let currentInstance = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration else {
            throw(APIService.APIError.implicit(.authenticationMissing))
        }
        
        let canUseGroupedNotifications = {
            switch scope {
            case .everything, .mentions:
                return currentInstance.isAvailable(.groupNotifications)
            case .fromRequest:
                return false
            }
        }()
        
        let results: [GroupedNotificationInfo]
        if canUseGroupedNotifications {
            results = try await getGroupedNotifications(withScope: scope, olderThan: olderThan, newerThan: newerThan)
        } else {
            results = try await getUngroupedNotifications(withScope: scope, olderThan: olderThan, newerThan: newerThan)
        }
        return results
    }
    
    static private func currentUser() throws -> MastodonAuthenticationBox {
        guard
            let authenticationBox = AuthenticationServiceProvider.shared
                .currentActiveUser.value
        else { throw APIService.APIError.implicit(.authenticationMissing) }
        return authenticationBox
    }
    
    static private func getUngroupedNotifications(
        withScope scope: NotificationsScope, olderThan maxID: String? = nil, newerThan minID: String?
    ) async throws -> [GroupedNotificationInfo] {
        let authenticationBox = try currentUser()
        
        let ungrouped: [Mastodon.Entity.Notification]
        switch scope {
        case .everything:
            ungrouped = try await APIService.shared.notifications(
                olderThan: maxID, fromAccount: nil, scope: .everything,
                authenticationBox: authenticationBox
            ).value
        case .mentions:
            ungrouped = try await APIService.shared.notifications(
                olderThan: maxID, fromAccount: nil, scope: .mentions,
                authenticationBox: authenticationBox
            ).value
        case .fromRequest(let request):
            ungrouped = try await APIService.shared.notifications(
                olderThan: maxID, fromAccount: request.account.id, scope: nil,
                authenticationBox: authenticationBox
            ).value
        }
        
        return ungrouped.map { notification in
            let sourceAccounts = NotificationSourceAccounts(myAccountID: authenticationBox.domain, accounts: [notification.account], totalActorCount: 1)
            let notificationType = GroupedNotificationType(notification, myAccountDomain: authenticationBox.domain, sourceAccounts: sourceAccounts, adminReportID: nil)
            let navigation = NotificationRowViewModel.defaultNavigation(notificationType, isGrouped: false, primaryAccount: notification.account)
            let post = notification.status == nil ? nil : GenericMastodonPost.fromStatus(notification.status!)
            let info = GroupedNotificationInfo(id: notification.id, timestamp: notification.createdAt, oldestNotificationID: notification.id, newestNotificationID: notification.id, groupedNotificationType: notificationType, sourceAccounts: sourceAccounts, post:  post, primaryNavigation: navigation)
            return info
        }
    }
    
    static private func getGroupedNotifications(
        withScope scope: NotificationsScope, olderThan maxID: String? = nil, newerThan minID: String?
    ) async throws -> [GroupedNotificationInfo] {
        let authenticationBox = try currentUser()
        
        let adminFilterPreferences = await BodegaPersistence.Notifications.currentPreferences(for: authenticationBox)
        let results: Mastodon.Entity.GroupedNotificationsResults
        switch scope {
        case .everything:
            results = try await APIService.shared.groupedNotifications(
                olderThan: maxID, newerThan: minID, fromAccount: nil, scope: .everything, excludingAdminTypes: adminFilterPreferences?.excludedNotificationTypes,
                authenticationBox: authenticationBox
            )
        case .mentions:
            results = try await APIService.shared.groupedNotifications(
                olderThan: maxID, newerThan: minID, fromAccount: nil, scope: .mentions, excludingAdminTypes: adminFilterPreferences?.excludedNotificationTypes,
                authenticationBox: authenticationBox
            )
        case .fromRequest:
            assertionFailure("notifications from a particular account must use the ungrouped api")
            results = try await APIService.shared.groupedNotifications(
                olderThan: maxID, newerThan: minID, fromAccount: nil, scope: nil, excludingAdminTypes: adminFilterPreferences?.excludedNotificationTypes,
                authenticationBox: authenticationBox
            )
        }
        
        let fullAccounts = results.accounts.reduce(
            into: [String: Mastodon.Entity.Account]()
        ) { partialResult, account in
            partialResult[account.id] = account
        }
        let partialAccounts = results.partialAccounts?.reduce(
            into: [String: Mastodon.Entity.PartialAccountWithAvatar]()
        ) { partialResult, account in
            partialResult[account.id] = account
        }
        
        let statuses = results.statuses.reduce(
            into: [String: Mastodon.Entity.Status](),
            { partialResult, status in
                partialResult[status.id] = status
            })
        
        return results.notificationGroups.map { group in
            let accounts: [AccountInfo] = group.sampleAccountIDs.compactMap { accountID in
                return fullAccounts[accountID] ?? partialAccounts?[accountID]
            }
            
            let sourceAccounts = NotificationSourceAccounts(
                myAccountID: authenticationBox.userID, accounts: accounts,
                totalActorCount: group.notificationsCount)
            
            let status = group.statusID == nil ? nil : statuses[group.statusID!]
            
            let type = GroupedNotificationType(
                group, myAccountDomain: authenticationBox.domain, sourceAccounts: sourceAccounts, status: status, adminReportID: group.adminReport?.id)
            
            let post = status == nil ? nil : GenericMastodonPost.fromStatus(status!)
            
            return GroupedNotificationInfo(
                id: group.id,
                timestamp: group.latestPageNotificationAt,
                oldestNotificationID: group.pageNewestID ?? "",
                newestNotificationID: group.pageOldestID ?? "",
                groupedNotificationType: type,
                sourceAccounts: sourceAccounts,
                post: post,
                primaryNavigation: NotificationRowViewModel.defaultNavigation(
                    type, isGrouped: group.notificationsCount > 1,
                    primaryAccount: sourceAccounts.primaryAuthorAccount)
            )
        }
    }
    
}
