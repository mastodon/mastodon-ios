// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonCore
import MastodonSDK

public class FeedCoordinator {
    @Published var mostRecentUpdate: UpdatedElement?
    
    static let shared = FeedCoordinator()
    
    func publishUpdate(_ update: UpdatedElement) {
        mostRecentUpdate = update
        switch update {
        case .relationship:
            Task { @MainActor in
                guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value?.globallyUniqueUserIdentifier else { return }
                AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: currentUser)
            }
        default:
            break
        }
    }
}

enum UpdatedElement {
    case deletedPost(Mastodon.Entity.Status.ID)
    case post(GenericMastodonPost)
    case hashtag(Mastodon.Entity.Tag)
    case relationship(MastodonAccount.Relationship)
}

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

public enum DiscoveryType: Equatable {
    case posts
    case hashtags
}
                                
public enum MastodonTimelineType: Equatable {
    case homeTimeline
    case myBookmarks
    case myFavorites
    case myFollowedHashtags
    case local
    case list(String)
    case hashtag(Mastodon.Entity.Tag, includeHeader: Bool)
    case discover(DiscoveryType)
    case search(String, SearchScope)
    case userPosts(userID: String, queryFilter: TimelineQueryFilter)
    case followers(ofUserId: String)
    case accountsFollowed(byUserId: String)
    case thread(root: MastodonContentPost)
    case remoteThread(remoteType: RemoteThreadType)
    case notifications(scope: NotificationsScope)
    case whoFavourited(actionableStatusID: Mastodon.Entity.Status.ID)

    public static func == (lhs: MastodonTimelineType, rhs: MastodonTimelineType) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimeline, .homeTimeline):
            return true
        case (.local, .local):
            return true
        case (.list(let first), .list(let second)):
            return first == second
        case (.hashtag(let firstTag, let firstHeader), .hashtag(let secondTag, let secondHeader)):
            return firstTag == secondTag && firstHeader == secondHeader
        case (.discover(let firstType), .discover(let secondType)):
            return firstType == secondType
        case (.search(let firstText, let firstScope), .search(let secondText, let secondScope)):
            return firstText == secondText && firstScope == secondScope
        case (.userPosts(let firstID, let firstFilter), .userPosts(let secondID, let secondFilter)):
            return firstID == secondID && firstFilter == secondFilter
        case (.thread(let first), .thread(let second)):
            return first.id == second.id
        case (.notifications(let firstScope), .notifications(let secondScope)):
            return firstScope == secondScope
        default:
            return false
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
        case .homeTimeline:
            return true
        default:
            return false
        }
    }
    
    public var filterContext: Mastodon.Entity.FilterContext? {
        switch self {
        case .homeTimeline:
                .home
        case .hashtag:
                .public
        case .list:
                .home
        case .local:
                .public
        case .discover:
                .public
        case .search:
            nil
        case .userPosts:
                .account
        case .accountsFollowed, .followers:
            nil
        case .thread, .remoteThread:
                .account
        case .myFollowedHashtags:
            nil
        case .myBookmarks:
            nil
        case .myFavorites:
            nil
        case .notifications:
                .notifications
        case .whoFavourited:
            nil
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
        let filterOutInContexts: Set<Mastodon.Entity.FilterContext>
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
    case hashtag(HashtagRowViewModel)
    case account(AccountRowViewModel)
    case filteredNotificationsInfo(
        Mastodon.Entity.NotificationPolicy?,
        FilteredNotificationsRowView.ViewModel?)
    case loadingIndicator
    case noItem
    
    var id: String {
        switch self {
        case .post(let postViewModel):
            return "post-\(postViewModel.initialDisplayInfo.id)"
        case .notification(let groupedNotificationInfo):
            return "notification-\(groupedNotificationInfo.id)"
        case .hashtag(let tagViewModel):
            return "hashtag-\(tagViewModel.id)"
        case .account(let accountViewModel):
            return "account-\(accountViewModel.id)"
        case .filteredNotificationsInfo:
            return "filteredNotifications"
        case .loadingIndicator:
            return "loading..."
        case .noItem:
            return "NO ITEM"
        }
    }
    
    var mastodonID: String? {
        switch self {
        case .post(let postViewModel):
            return postViewModel.initialDisplayInfo.id
        case .notification(let groupedNotificationInfo):
            return groupedNotificationInfo.id
        case .hashtag(let tagViewModel):
            return tagViewModel.id
        case .account(let accountViewModel):
            return accountViewModel.id
        case .filteredNotificationsInfo:
            return nil
        case .loadingIndicator:
            return nil
        case .noItem:
            return nil
        }
    }
    
    var isRealItem: Bool {
        switch self {
        case .post, .notification, .hashtag, .account:
            return true
        case .filteredNotificationsInfo, .loadingIndicator, .noItem:
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

protocol FeedCoordinatorUpdatable {
    @MainActor func incorporateUpdate(_ update: UpdatedElement)
}

@MainActor
final class TimelineFeedLoader: MastodonFeedLoader<TimelineItem, CacheableTimeline> {
#if DEBUG
    private var _createArtificialGapForTesting = false
#endif
    
    private let authenticatedUser: MastodonAuthenticationBox
    
    private var cachedRelationships = [Mastodon.Entity.Account.ID : MastodonAccount.Relationship]()
    private var accountsCache = [Mastodon.Entity.Account.ID : MastodonAccount]()
    private var contentConcealViewModels = [Mastodon.Entity.Status.ID : ContentConcealViewModel]()
    
    private var updateSubscription: AnyCancellable?
    private var postViewModels = [Mastodon.Entity.Status.ID : MastodonPostViewModel]()
    private var notificationViewModels = [Mastodon.Entity.NotificationGroup.ID : NotificationRowViewModel]()
    private var accountViewModels = [Mastodon.Entity.Account.ID : AccountRowViewModel]()
    private var hashtagViewModels = [String : HashtagRowViewModel]()
    
    private let myAccountID: Mastodon.Entity.Account.ID?
    
    let timeline: MastodonTimelineType
    var threadedConversationModel: ThreadedConversationModel?
    
    init(currentUser: MastodonAuthenticationBox, timeline: MastodonTimelineType) {
        self.timeline = timeline
        authenticatedUser = currentUser
        myAccountID = authenticatedUser.cachedAccount?.id
        let trackLastRead = timeline == .homeTimeline
        let cacheManager = TimelineCacheManager(currentUser: currentUser, trackLastRead: trackLastRead, useDiskCache: false)
        
        super.init(cacheManager)
        
        self.updateSubscription = FeedCoordinator.shared.$mostRecentUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                guard let self, let update else { return }
                switch update {
                case .deletedPost(let deletedID):
                    transformCachedResults { cache in
                        return cache.byDeleting(postId: deletedID)
                    }
                case .relationship(let updated):
                    guard let id = updated.info?.id else { return }
                    self.cachedRelationships[id] = updated
                default:
                    break
                }
                updateCachedResults { cache in
                    for item in cache.items {
                        switch item {
                        case .account(let accountModel):
                            accountModel.incorporateUpdate(update)
                        case .post:
                            break // this update is handled by the CentralPostViewModelCache
                        case .notification(let notificationModel):
                            notificationModel.incorporateUpdate(update)
                        case .hashtag(let hashtagModel):
                            hashtagModel.incorporateUpdate(update)
                        case .filteredNotificationsInfo, .loadingIndicator, .noItem:
                            break
                        }
                    }
                }
            }
    }

    override func fetchResults(for request: MastodonFeedLoaderRequest) async throws -> CacheableTimeline {
        
        await AuthenticationServiceProvider.shared.fetchAccounts(onlyIfItHasBeenAwhile: true) // TODO: legacy comments indicated this may not be the best place for this call
        
        let loadUrl: URL? = {
            switch request {
            case .newer, .reload:
                return nil
            case .older:
                switch records.nextBottomLoad {
                case .initializing, .nothingMoreToLoad:
                    return nil
                case .link(let url):
                    return url
                case .offset:
                    return nil
                }
            }
        }()
        var newPostModels = [Mastodon.Entity.Status.ID : MastodonPostViewModel]()
        var newNotificationModels = [Mastodon.Entity.NotificationGroup.ID : NotificationRowViewModel]()
        var newAccountModels = [Mastodon.Entity.Account.ID : AccountRowViewModel]()
        var newHashtagModels = [String : HashtagRowViewModel]()
        
        func timelineItem(fromStatus status: Mastodon.Entity.Status) -> TimelineItem {
            let post = GenericMastodonPost.fromStatus(status)
            return timelineItem(fromPost: post)
        }
        func timelineItem(fromPost post: GenericMastodonPost) -> TimelineItem {
            let initialDisplayInfo = post.initialDisplayInfo()
            let viewModel = {
                if let existing = postViewModels[initialDisplayInfo.id] {
                    existing.incorporateUpdate(.post(post))
                    return existing
                } else {
                    // possible that another timeline has a view model for this post, even though we don't
                    if let existingElsewhere = CentralPostViewModelCache.shared.cachedModel(for: initialDisplayInfo.id) {
                        existingElsewhere.incorporateUpdate(.post(post))
                        newPostModels[initialDisplayInfo.id] = existingElsewhere
                        return existingElsewhere
                    } else {
                        let model = MastodonPostViewModel(initialDisplayInfo)
                        model.initialSetFullPost(post)
                        newPostModels[initialDisplayInfo.id] = model
                        CentralPostViewModelCache.shared.addToCache(model)
                        return model
                    }
                }
            }()
            return TimelineItem.post(viewModel)
        }
        func timelineItem(fromAccount accountEntity: Mastodon.Entity.Account) -> TimelineItem {
            let account = MastodonAccount.fromEntity(accountEntity)
            let viewModel = {
                if let existing = accountViewModels[account.id] {
                    existing.updateAccount(account)
                    return existing
                } else {
                    let model = AccountRowViewModel(account: account)
                    newAccountModels[account.id] = model
                    return model
                }
            }()
            return TimelineItem.account(viewModel)
        }
        func timelineItem(fromHashtag hashtag: Mastodon.Entity.Tag) -> TimelineItem {
            let viewModel = {
                if let existing = hashtagViewModels[hashtag.uniqueID] {
                    existing.incorporateUpdate(.hashtag(hashtag))
                    return existing
                } else {
                    return HashtagRowViewModel(entity: hashtag)
                }
            }()
            newHashtagModels[hashtag.uniqueID] = viewModel
            return TimelineItem.hashtag(viewModel)
        }

        let newBatch: [TimelineItem]
        let newBatchBottomLoad: BottomLoad
        switch timeline {
        case .homeTimeline:
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.homeTimeline(authenticationBox: authenticatedUser)
                }
            }()
            let result = response.value
            newBatch = result.map { timelineItem(fromStatus:$0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl, timeline == .homeTimeline {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
        case .local:
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.publicTimeline(
                        query: .init(local: true),
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromStatus: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
        case .list(let listId):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.listTimeline(
                        id: listId,
                        query: .init(local: true),
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromStatus: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
        case .hashtag(let hashtag, let includeHeader):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.hashtagTimeline(
                        hashtag: hashtag.name,
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            let statuses = response.value.map { timelineItem(fromStatus: $0) }
            if includeHeader {
                let header: TimelineItem
                if request == .reload || request == .newer,
                   let updated = try? await APIService.shared.getTagInformation(
                    for: hashtag.name,
                    authenticationBox: authenticatedUser
                   ).value {
                    header = timelineItem(fromHashtag: updated)
                } else {
                    header = timelineItem(fromHashtag: hashtag)
                }
                newBatch = [header] + statuses
            } else {
                newBatch = statuses
            }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
        case .discover(let discoverType):
            switch discoverType {
            case .posts:
                let response = try await {
                    if let loadUrl {
                        return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                    } else {
                        return try await APIService.shared.trendStatuses(
                            domain: authenticatedUser.domain,
                            query: Mastodon.API.Trends.StatusQuery(
                                offset: 0,
                                limit: nil
                            ),
                            authenticationBox: authenticatedUser
                        )
                    }
                }()
                newBatch = response.value.map { timelineItem(fromStatus: $0) }
                newBatchBottomLoad = {
                    if let url = response.link?.nextUrl {
                        return .link(url)
                    } else {
                        return .nothingMoreToLoad
                    }
                }()
            case .hashtags:
                let response = try await {
                    if let loadUrl {
                        return try await APIService.shared.hashtags(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                    } else {
                        return try await APIService.shared.trendHashtags(
                            domain: authenticatedUser.domain,
                            query: Mastodon.API.Trends.HashtagQuery(
                                limit: nil
                            ),
                            authenticationBox: authenticatedUser
                        )
                    }
                }()
                newBatch = response.value.map { timelineItem(fromHashtag: $0) }
                newBatchBottomLoad = {
                    if let url = response.link?.nextUrl {
                        return .link(url)
                    } else {
                        return .nothingMoreToLoad
                    }
                }()
            }
        case .search(let searchText, let scope):
            let query = Mastodon.API.V2.Search.Query(
                q: searchText,
                type: scope.searchType,
                accountID: nil,
                maxID: nil,
                minID: nil,
                excludeUnreviewed: nil,
                resolve: true,
                limit: nil,
                offset: 0,
                following: nil
            )
            let response = try await APIService.shared.search(
                query: query,
                authenticationBox: authenticatedUser
            )
            let results = response.value
            let statuses = results.statuses.map { timelineItem(fromStatus: $0) }
            let hashtags = results.hashtags.map { timelineItem(fromHashtag: $0) }
            let accounts = results.accounts.map { timelineItem(fromAccount: $0) }
            newBatch = accounts + hashtags + statuses
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
        case .userPosts(let userID, let queryFilter):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.userTimeline(
                        accountID: userID,
                        excludeReplies: queryFilter.excludeReplies,
                        excludeReblogs: queryFilter.excludeReblogs,
                        onlyMedia: queryFilter.onlyMedia,
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromStatus: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
        case .accountsFollowed(let userId):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.accounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.following(userID: userId, maxID: nil, authenticationBox: authenticatedUser)
                }
            }()
            newBatch = response.value.map { timelineItem(fromAccount: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
        case .followers(let userId):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.accounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.followers(userID: userId, maxID: nil, authenticationBox: authenticatedUser)
                }
            }()
            newBatch = response.value.map { timelineItem(fromAccount: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
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
            newBatchBottomLoad = .nothingMoreToLoad  // pagination is not possible, only reloading
            
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
            newBatchBottomLoad = .nothingMoreToLoad  // pagination is not possible, only reloading
            
        case .myFollowedHashtags:
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.hashtags(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.getFollowedTags(
                        domain: authenticatedUser.domain,
                        query: Mastodon.API.Account.FollowedTagsQuery(limit: nil),
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromHashtag: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
        case .myBookmarks:
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.bookmarkedStatuses(
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromStatus: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
        case .myFavorites:
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.favoritedStatuses(
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromStatus: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
        case .whoFavourited(let actionableStatusID):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.accounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.favoritedBy(
                        actionableStatusID: actionableStatusID,
                        query: .init(maxID: nil, limit: nil),
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromAccount: $0) }
            newBatchBottomLoad = {
                if let url = response.link?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
            
        case .notifications(scope: let scope):
            print("loading notifications request \(request)")
            let response = try await {
                if let loadUrl {
                    return try await NotificationsLoader.getNotifications(fromUrl: loadUrl, scope: scope)
                } else {
                    return try await NotificationsLoader.getNotifications(withScope: scope, olderThan: nil, newerThan: nil)
                }
            }()
            newBatch = response.0.map { groupedNotificationInfo in
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
            newBatchBottomLoad = {
                if let url = response.1?.nextUrl {
                    return .link(url)
                } else {
                    return .nothingMoreToLoad
                }
            }()
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
        newCache = CacheableTimeline(older: [], olderBottomLoad: newBatchBottomLoad, newer: newBatch, newerBottomLoad: newBatchBottomLoad, discardOlderIfNoOverlap: false)
#endif

        postViewModels = newPostModels
        notificationViewModels = newNotificationModels
        accountViewModels = newAccountModels
        hashtagViewModels = newHashtagModels
        createContentConcealViewModels(newCache)
        try? await fetchReplyTos(newCache)
        
        return newCache
    }
    
    override func filteredResults(fromCachedType cached: CacheableTimeline) -> [TimelineItem] {
        cached.filteredItems(inContext: timeline.filterContext)
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
    let nextBottomLoad: BottomLoad
    
    @MainActor
    func filteredItems(inContext context: Mastodon.Entity.FilterContext?) -> [TimelineItem] {
        return items.filter { item in
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo:
                return true
            case .noItem:
                return false
            case .post(let postViewModel):
                if let contentPost = postViewModel.fullPost as? MastodonContentPost {
                    return !contentPost.content.shouldBeRemovedFromFeed(inContext: context)
                } else if let boost = postViewModel.fullPost as? MastodonBoostPost {
                    return !boost.boostedPost.content.shouldBeRemovedFromFeed(inContext: context)
                } else if let context {
                    return !postViewModel.initialDisplayInfo.filterOutInContexts.contains(context)
                } else {
                    return true
                }
            case .notification(let groupedInfo):
                // TODO: filter based on contained statuses
                return true
            case .hashtag, .account:
                return true
            }
        }
    }
    
    var hasResults: Bool {
        return !items.isEmpty
    }
 
    init(older: [TimelineItem], olderBottomLoad: BottomLoad, newer: [TimelineItem], newerBottomLoad: BottomLoad, discardOlderIfNoOverlap: Bool) {
        
        let combined: [TimelineItem]
        let bottomLoad: BottomLoad
        
        if discardOlderIfNoOverlap {
            let oldestIdInNewBatch = newer.last(where: { item in
                switch item {
                case .loadingIndicator, .filteredNotificationsInfo, .noItem: return false
                case .post: return true
                case .notification: return true
                case .hashtag: return true
                case .account: return true
                }
            })?.id
            
            if let oldestIdInNewBatch {
                let overlapIndex = older.firstIndex(where: { item in
                    switch item {
                    case .post:
                        return item.id == oldestIdInNewBatch
                    case .notification:
                        return item.id == oldestIdInNewBatch
                    case .hashtag:
                        return item.id == oldestIdInNewBatch
                    case .account:
                        return item.id == oldestIdInNewBatch
                    case .loadingIndicator, .filteredNotificationsInfo, .noItem:
                        return false
                    }
                })
                if let overlapIndex {
                    let firstOlderIndexToRetain = overlapIndex + 1
                    if firstOlderIndexToRetain < older.count {
                        let olderTail = older.suffix(from: firstOlderIndexToRetain)
                        combined = newer + olderTail
                        bottomLoad = olderBottomLoad
                    } else {
                        combined = newer
                        bottomLoad = newerBottomLoad
                    }
                } else {
                    combined = newer  // do not allow gaps
                    bottomLoad = newerBottomLoad
                }
            } else {
                assert(newer.isEmpty, "How else did we get here?")
                combined = older
                bottomLoad = olderBottomLoad
            }
        } else {
            combined = newer + older
            bottomLoad = olderBottomLoad
        }
        
        items = combined
        nextBottomLoad = bottomLoad
    }
  
    @MainActor
    func byDeleting(postId: Mastodon.Entity.Status.ID) -> CacheableTimeline {
        let newItems = items.filter { item in
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo, .hashtag, .account:
                return true
            case .post(let postViewModel):
                return postViewModel.fullPost?.actionablePost?.id != postId
            case .notification:
                // TODO: anything?
                return true
            case .noItem:
                return false
            }
        }
        
        return CacheableTimeline(older: [], olderBottomLoad: nextBottomLoad, newer: newItems, newerBottomLoad: nextBottomLoad, discardOlderIfNoOverlap: false)
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
                self.staleResults = CacheableTimeline(older: [], olderBottomLoad: .nothingMoreToLoad, newer: timeline, newerBottomLoad: .nothingMoreToLoad, discardOlderIfNoOverlap: false)
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
        let current = currentResults()
        switch insertionPoint {
        case .start:
            mostRecentlyFetchedResults = CacheableTimeline(older: current?.items ?? [], olderBottomLoad: current?.nextBottomLoad ?? .initializing, newer: newlyFetched.items, newerBottomLoad: newlyFetched.nextBottomLoad, discardOlderIfNoOverlap: true)
        case .end:
            mostRecentlyFetchedResults = CacheableTimeline(older: newlyFetched.items, olderBottomLoad: newlyFetched.nextBottomLoad, newer: current?.items ?? [], newerBottomLoad: current?.nextBottomLoad ?? .initializing, discardOlderIfNoOverlap: false)
        case .replace:
            mostRecentlyFetchedResults = newlyFetched
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
    var removeFromFeedInContexts: Set<Mastodon.Entity.FilterContext> {
        guard let filterResults = filtered else { return Set() }
        var contexts = Set<Mastodon.Entity.FilterContext>()
        for result in filterResults {
            if result.filter.filterAction == .hide {
                for filterContext in result.filter.context {
                    contexts.insert(filterContext)
                }
            }
        }
        return contexts
    }
    
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

// MARK: Relationships
extension TimelineFeedLoader {
    func myRelationship(to accountID: Mastodon.Entity.Account.ID) -> MastodonAccount.Relationship {
        if accountID == myAccountID {
            return .isMe
        } else {
            return cachedRelationships[accountID] ?? .isNotMe(nil)
        }
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
            case .loadingIndicator, .filteredNotificationsInfo, .hashtag, .account, .noItem:
                break
            case .post(let postViewModel):
                if let contentPost = postViewModel.fullPost?.actionablePost, contentConcealViewModels[contentPost.id] == nil {
                    contentConcealViewModels[contentPost.id] = ContentConcealViewModel(contentPost: contentPost, context: timeline.filterContext)
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
    func initialDisplayInfo() -> GenericMastodonPost.InitialDisplayInfo {
        let author = actionablePost?.metaData.author ?? metaData.author
        return GenericMastodonPost.InitialDisplayInfo(id: id, actionablePostID: actionablePost?.id ?? id, filterOutInContexts: actionablePost?.content.removeFromFeedInContexts ?? Set(), actionableAuthorId: author.id, actionableAuthorStaticAvatar: author.displayInfo.avatarUrl, actionableAuthorHandle: author.handle, actionableAuthorDisplayName: author.displayName(whenViewedBy: nil)?.plainString ?? "", actionableVisibility: actionablePost?.metaData.privacyLevel ?? metaData.privacyLevel ?? .loudPublic, actionableCreatedAt: actionablePost?.metaData.createdAt ?? metaData.createdAt)
    }
}

@MainActor
struct NotificationsLoader {
    
    static func getNotifications(withScope scope: NotificationsScope, olderThan: String? = nil, newerThan: String?) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?) {
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
        
        if canUseGroupedNotifications {
            return try await getGroupedNotifications(withScope: scope, olderThan: olderThan, newerThan: newerThan)
        } else {
            return try await getUngroupedNotifications(withScope: scope, olderThan: olderThan, newerThan: newerThan)
        }
    }
    
    static func getNotifications(fromUrl url: URL, scope: NotificationsScope) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?) {
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
        
        return try await getNotifications(fromUrl: url, grouped: canUseGroupedNotifications)
    }
    
    static private func currentUser() throws -> MastodonAuthenticationBox {
        guard
            let authenticationBox = AuthenticationServiceProvider.shared
                .currentActiveUser.value
        else { throw APIService.APIError.implicit(.authenticationMissing) }
        return authenticationBox
    }
     
    static private func getNotifications(fromUrl url: URL, grouped: Bool) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?) {
        let authenticationBox = try currentUser()
        
        if grouped {
            let response = try await APIService.shared.groupedNotifications(fromUrl: url, authenticationBox: authenticationBox)
            let infos = groupedNotificationInfos(fromGroupedNotifications: response.value, authenticationBox: authenticationBox)
            return (infos, response.link)
        } else {
            let response = try await APIService.shared.ungroupedNotifications(fromUrl: url, authenticationBox: authenticationBox)
            let infos = groupedNotificationInfos(fromUngroupedNotifications: response.value, authenticationBox: authenticationBox)
            return (infos, response.link)
        }
        
    }
    
    static private func getUngroupedNotifications(
        withScope scope: NotificationsScope, olderThan maxID: String? = nil, newerThan minID: String?
    ) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?) {
        let authenticationBox = try currentUser()
        
        let response = try await {
            switch scope {
            case .everything:
                return try await APIService.shared.notifications(
                    olderThan: maxID, fromAccount: nil, scope: .everything,
                    authenticationBox: authenticationBox
                )
            case .mentions:
                return try await APIService.shared.notifications(
                    olderThan: maxID, fromAccount: nil, scope: .mentions,
                    authenticationBox: authenticationBox
                )
            case .fromRequest(let request):
                return try await APIService.shared.notifications(
                    olderThan: maxID, fromAccount: request.account.id, scope: nil,
                    authenticationBox: authenticationBox
                )
            }
        }()
        
        let infos = groupedNotificationInfos(fromUngroupedNotifications: response.value, authenticationBox: authenticationBox)
        return (infos, response.link)
    }
    
    static private func groupedNotificationInfos(fromUngroupedNotifications ungroupedNotifications: [Mastodon.Entity.Notification], authenticationBox: MastodonAuthenticationBox) -> [GroupedNotificationInfo] {
        return ungroupedNotifications.map { notification in
            let sourceAccounts = NotificationSourceAccounts(myAccountID: authenticationBox.domain, accounts: [notification.account], totalActorCount: 1)
            let notificationType = GroupedNotificationType(notification, myAccountDomain: authenticationBox.domain, sourceAccounts: sourceAccounts, adminReportID: nil)
            let navigation = NotificationRowViewModel.defaultNavigation(notificationType, isGrouped: false, primaryAccount: notification.account)
            let post = notification.status == nil ? nil : GenericMastodonPost.fromStatus(notification.status!)
            let info = GroupedNotificationInfo(id: notification.id, timestamp: notification.createdAt, oldestNotificationID: notification.id, newestNotificationID: notification.id, groupedNotificationType: notificationType, sourceAccounts: sourceAccounts, post:  post, primaryNavigation: navigation)
            return info
        }
    }
    
    static private func groupedNotificationInfos(fromGroupedNotifications groupedNotifications: Mastodon.Entity.GroupedNotificationsResults, authenticationBox: MastodonAuthenticationBox) -> [GroupedNotificationInfo] {
        let fullAccounts = groupedNotifications.accounts.reduce(
            into: [String: Mastodon.Entity.Account]()
        ) { partialResult, account in
            partialResult[account.id] = account
        }
        let partialAccounts = groupedNotifications.partialAccounts?.reduce(
            into: [String: Mastodon.Entity.PartialAccountWithAvatar]()
        ) { partialResult, account in
            partialResult[account.id] = account
        }
        
        let statuses = groupedNotifications.statuses.reduce(
            into: [String: Mastodon.Entity.Status](),
            { partialResult, status in
                partialResult[status.id] = status
            })
        
        let groups = groupedNotifications.notificationGroups.map { group in
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
        
        return groups
    }
    
    static private func getGroupedNotifications(
        withScope scope: NotificationsScope, olderThan maxID: String? = nil, newerThan minID: String?
    ) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?) {
        let authenticationBox = try currentUser()
        
        let adminFilterPreferences = await BodegaPersistence.Notifications.currentPreferences(for: authenticationBox)
        let response: Mastodon.Response.Content<Mastodon.Entity.GroupedNotificationsResults> = try await {
            switch scope {
            case .everything:
                return try await APIService.shared.groupedNotifications(
                    olderThan: maxID, newerThan: minID, fromAccount: nil, scope: .everything, excludingAdminTypes: adminFilterPreferences?.excludedNotificationTypes,
                    authenticationBox: authenticationBox
                )
            case .mentions:
                return try await APIService.shared.groupedNotifications(
                    olderThan: maxID, newerThan: minID, fromAccount: nil, scope: .mentions, excludingAdminTypes: adminFilterPreferences?.excludedNotificationTypes,
                    authenticationBox: authenticationBox
                )
            case .fromRequest:
                assertionFailure("notifications from a particular account must use the ungrouped api")
                return try await APIService.shared.groupedNotifications(
                    olderThan: maxID, newerThan: minID, fromAccount: nil, scope: nil, excludingAdminTypes: adminFilterPreferences?.excludedNotificationTypes,
                    authenticationBox: authenticationBox
                )
            }
        }()
        
        let results = response.value
        
        let groups = groupedNotificationInfos(fromGroupedNotifications: results, authenticationBox: authenticationBox)
        
        return (groups, response.link)
    }
    
}
