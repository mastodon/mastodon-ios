// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Combine
import Foundation
import MastodonCore
import MastodonSDK
import MastodonLocalization

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
    case domainBlockChange(domain: String, isBlocked: Bool)
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
    case news
    case forYou
}

public class SearchQueryModel: Identifiable {
    public let id = UUID()
    var trimmedSearchString: String = ""
    var scope: SearchScope = .all
}
                                
public enum MastodonTimelineType: Equatable {
    // *** WHEN ADDING A CASE, make sure to update the == definition below
    case homeTimeline
    case myBookmarks
    case myFavorites
    case myFollowedHashtags
    case local
    case list(String)
    case hashtag(Mastodon.Entity.Tag, includeHeader: Bool)
    case collection(CollectionViewModel)
    case discover(DiscoveryType)
    case linkMentions(String)
    case search(SearchQueryModel)
    case userPosts(userID: String, queryFilter: TimelineQueryFilter)
    case featuredItems(userID: String)
    case followers(ofUserId: String)
    case accountsFollowed(byUserId: String)
    case familiarFollowers(Mastodon.Entity.Account.ID)
    case postHistory(MastodonContentPost)
    case thread(root: MastodonContentPost)
    case remoteThread(remoteType: RemoteThreadType)
    case notifications(scope: NotificationsScope)
    case notificationRequests
    case whoFavourited(actionableStatusID: Mastodon.Entity.Status.ID)
    case whoBoosted(actionableStatusID: Mastodon.Entity.Status.ID)
    // *** WHEN ADDING A CASE, make sure to update the == definition below

    public static func == (lhs: MastodonTimelineType, rhs: MastodonTimelineType) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimeline, .homeTimeline):
            return true
        case (.myBookmarks, .myBookmarks):
            return true
        case (.myFavorites, .myFavorites):
            return true
        case (.myFollowedHashtags, .myFollowedHashtags):
            return true
        case (.local, .local):
            return true
        case (.list(let first), .list(let second)):
            return first == second
        case (.hashtag(let firstTag, let firstHeader), .hashtag(let secondTag, let secondHeader)):
            return firstTag == secondTag && firstHeader == secondHeader
        case (.discover(let firstType), .discover(let secondType)):
            return firstType == secondType
        case (.linkMentions(let firstURL), .linkMentions(let secondURL)):
            return firstURL == secondURL
        case (.search(let first), .search(let second)):
            return first.id == second.id
        case (.userPosts(let firstID, _), .userPosts(let secondID, _)):
            return firstID == secondID
        case (.featuredItems(let userIDFirst), .featuredItems(let userIDSecond)):
            return userIDFirst == userIDSecond
        case (.followers(let ofUserIdFirst), .followers(let ofUserIdSecond)):
            return ofUserIdFirst == ofUserIdSecond
        case (.accountsFollowed(let byUserIdFirst), .accountsFollowed(let byUserIdSecond)):
            return byUserIdFirst == byUserIdSecond
        case (.familiarFollowers(let accountIdFirst), .familiarFollowers(let accountIdSecond)):
            return accountIdFirst == accountIdSecond
        case (.postHistory(let first), .postHistory(let second)):
            return first.id == second.id
        case (.thread(let first), .thread(let second)):
            return first.id == second.id
        case (.remoteThread(let remoteTypeFirst), .remoteThread(let remoteTypeSecond)):
            switch (remoteTypeFirst, remoteTypeSecond) {
            case (.status(let first), .status(let second)):
                return first == second
            case (.notification(let first), .notification(let second)):
                return first == second
            default:
                return false
            }
        case (.notifications(let firstScope), .notifications(let secondScope)):
            return firstScope == secondScope
        case (.notificationRequests, .notificationRequests):
            return true
        case (.whoFavourited(let actionableStatusIdFirst), .whoFavourited(let actionableStatusIdSecond)):
            return actionableStatusIdFirst == actionableStatusIdSecond
        case (.whoBoosted(let actionableStatusIdFirst), .whoBoosted(let actionableStatusIdSecond)):
            return actionableStatusIdFirst == actionableStatusIdSecond
        case (.collection(let collectionViewModelFirst), .collection(let collectionViewModelSecond)):
            return collectionViewModelFirst.id == collectionViewModelSecond.id
            
        default:
            return false
        }
    }
    
    public var isHistoryDisplay: Bool {
        switch self {
        case .postHistory:
            return true
        default:
            return false
        }
    }
    
    public var isCollection: Bool {
        switch self {
        case .collection:
            return true
        default:
            return false
        }
    }
    
    public var collectionViewModel: CollectionViewModel? {
        switch self {
        case .collection(let viewModel):
            return viewModel
        default:
            return nil
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
        case .collection:
            nil
        case .list:
                .home
        case .local:
                .public
        case .discover, .linkMentions:
                .public
        case .search:
            nil
        case .userPosts, .featuredItems:
                .account
        case .accountsFollowed, .followers, .familiarFollowers:
            nil
        case .thread, .remoteThread:
                .account
        case .postHistory:
            nil
        case .myFollowedHashtags:
            nil
        case .myBookmarks:
            nil
        case .myFavorites:
            nil
        case .notifications:
                .notifications
        case .notificationRequests:
            nil
        case .whoFavourited, .whoBoosted:
            nil
        }
    }
}

@Observable
@MainActor
public class TimelineQueryFilter {
    
    enum TimelineFilterType {
        case mediaOnly
        case userPosts(FeaturedHashtagsModel)
        case unfilterable
    }
    
    let filterType: TimelineFilterType
    var excludeReplies: Bool?
    var excludeReblogs: Bool?
    let onlyMedia: Bool?
    var selectedHashtag: Mastodon.Entity.FeaturedTag?
    
    init(_ type: TimelineFilterType) {
        switch type {
        case .mediaOnly:
            excludeReblogs = nil
            excludeReplies = nil
            onlyMedia = true
        case .userPosts:
            excludeReblogs = false
            excludeReplies = true
            onlyMedia = nil
        case .unfilterable:
            excludeReblogs = nil
            excludeReplies = nil
            onlyMedia = nil
        }
        self.filterType = type
    }
    
    var showBoostsAndRepliesFilterButton: Bool {
        switch filterType {
        case .userPosts:
            return true
        case .mediaOnly, .unfilterable:
            return false
        }
    }
    
    var featuredHashtagsModel: FeaturedHashtagsModel? {
        switch filterType {
        case .userPosts(let model):
            return model
        case .mediaOnly, .unfilterable:
            return nil
        }
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
    case heading(String)
    case pinnedPosts([TimelineItem])
    case post(MastodonPostViewModel, isPinned: Bool)
    case notification(NotificationRowViewModel)
    case notificationRequest(NotificationRequestModel)
    case hashtag(HashtagRowViewModel)
    case link(Mastodon.Entity.Card)
    case account(AccountRowViewModel)
    case collection(CollectionViewModel)
    case filteredNotificationsInfo(
        Mastodon.Entity.NotificationPolicy?,
        FilteredNotificationsRowView.ViewModel?)
    case loadingIndicator
    case noItem
    
    var id: String {
        switch self {
        case .heading(let string):
            return "heading-\(string)"
        case .pinnedPosts:
            return "pinnedPosts"
        case .post(let postViewModel, let isPinned):
            return "post-\(postViewModel.initialDisplayInfo.id)\(isPinned ? "-pinned" : "")"
        case .notification(let groupedNotificationInfo):
            return "notification-\(groupedNotificationInfo.id)"
        case .notificationRequest(let request):
            return "notificationRequest-\(request.id)"
        case .hashtag(let tagViewModel):
            return "hashtag-\(tagViewModel.id)"
        case .link(let link):
            return "link-\(link.url)"
        case .account(let accountViewModel):
            return "account-\(accountViewModel.id)"
        case .collection(let collectionViewModel):
            return "collection-\(collectionViewModel.id)"
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
        case .heading:
            return nil
        case .pinnedPosts:
            return nil
        case .post(let postViewModel, _):
            return postViewModel.initialDisplayInfo.id
        case .notification(let groupedNotificationInfo):
            return groupedNotificationInfo.id
        case .notificationRequest(let request):
            return request.id
        case .hashtag(let tagViewModel):
            return tagViewModel.id
        case .link(let link):
            return link.url
        case .account(let accountViewModel):
            return accountViewModel.id
        case .collection(let collectionViewModel):
            return collectionViewModel.id
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
        case .pinnedPosts, .post, .notification, .notificationRequest, .hashtag, .link, .account, .collection:
            return true
        case .heading, .filteredNotificationsInfo, .loadingIndicator, .noItem:
            return false
        }
    }
    
    var postViewModels: [MastodonPostViewModel] {
        switch self {
        case .pinnedPosts(let items):
            return items.flatMap {
                $0.postViewModels
            }
        case .post(let postViewModel, _):
            return [postViewModel]
        default:
            assertionFailure()
            return []
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
    private var collectionViewModels = [Mastodon.Entity.Collection.ID : CollectionViewModel]()
    private var hashtagViewModels = [String : HashtagRowViewModel]()
    
    private let myAccountID: Mastodon.Entity.Account.ID?
    
    let timeline: MastodonTimelineType
    var threadedConversationModel: ThreadedConversationModel?
    let asyncRefreshViewModel: AsyncRefreshViewModel?
    
    init(currentUser: MastodonAuthenticationBox, timeline: MastodonTimelineType, asyncRefreshViewModel: AsyncRefreshViewModel?) {
        self.timeline = timeline
        self.asyncRefreshViewModel = asyncRefreshViewModel
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
                        case .post, .pinnedPosts:
                            break // this update is handled by the CentralPostViewModelCache
                        case .notification(let notificationModel):
                            notificationModel.incorporateUpdate(update)
                        case .notificationRequest:
                            break
                        case .hashtag(let hashtagModel):
                            hashtagModel.incorporateUpdate(update)
                        case .filteredNotificationsInfo, .loadingIndicator, .noItem, .collection, .heading, .link:
                            break
                        }
                    }
                }
            }
    }

    override func resetTimeline() -> CacheableTimeline? {
        CacheableTimeline(older: [], olderBottomLoad: .initializing, newer: [], newerBottomLoad: .initializing, discardOlderIfNoOverlap: true)
    }
    
    override func fetchResults(for request: MastodonFeedLoaderRequest) async throws -> CacheableTimeline {
        
        await AuthenticationServiceProvider.shared.fetchAccounts(onlyIfItHasBeenAwhile: true) // TODO: legacy comments indicated this may not be the best place for this call
        
        let loadUrl: URL? = {
            switch request {
            case .newer, .reload, .reloadForFilterChange:
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
        var newCollectionModels = [Mastodon.Entity.Collection.ID : CollectionViewModel]()
        var newHashtagModels = [String : HashtagRowViewModel]()
        
        func timelineItem(fromStatus status: Mastodon.Entity.Status, isPinned: Bool) -> TimelineItem {
            let post = GenericMastodonPost.fromStatus(status, authenticatedDomain: authenticatedUser.domain)
            return timelineItem(fromPost: post, isPinned: isPinned || (status.pinned == true), isOriginal: nil)
        }
        func timelineItem(fromStatusEdit statusEdit: Mastodon.Entity.StatusEdit, actualStatus: MastodonContentPost, isOriginal: Bool) -> TimelineItem? {
            guard let post = MastodonBasicPost.fromStatusEdit(statusEdit, actualStatus: actualStatus, authenticatedDomain: authenticatedUser.domain) else { return nil }
            return timelineItem(fromPost: post, isPinned: false, isOriginal: isOriginal)
        }
        func timelineItem(fromPost post: GenericMastodonPost, isPinned: Bool, isOriginal: Bool?) -> TimelineItem {
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
                        let model = MastodonPostViewModel(initialDisplayInfo, displayType: timeline.isHistoryDisplay ? .editHistory(isOriginal: isOriginal == true) : .standard)
                        model.initialSetFullPost(post)
                        newPostModels[initialDisplayInfo.id] = model
                        CentralPostViewModelCache.shared.addToCache(model)
                        if let collectionModel = model.collectionViewModel {
                            newCollectionModels[collectionModel.id] = collectionModel
                        }
                        return model
                    }
                }
            }()
            let isPinnedByMe = (post as? MastodonContentPost)?.content.myActions.pinnedByMe
            return TimelineItem.post(viewModel, isPinned: isPinned || (isPinnedByMe == true))
        }
        func timelineItem(fromAccount accountEntity: Mastodon.Entity.Account, suggestedBecause: [Mastodon.Entity.V2.SuggestionAccount.SuggestionReason]?) -> TimelineItem {
            let account = MastodonAccount.fromEntity(accountEntity, authenticatedDomain: authenticatedUser.domain)
            let viewModel = {
                if let existing = accountViewModels[account.id] {
                    existing.updateAccount(account, suggestionReasons: suggestedBecause)
                    return existing
                } else {
                    let model = AccountRowViewModel(account: account, suggestedBecause: suggestedBecause)
                    newAccountModels[account.id] = model
                    return model
                }
            }()
            return TimelineItem.account(viewModel)
        }
        @MainActor func updateCollectionModel(_ model: CollectionViewModel, withAuthorAccountID authorID: Mastodon.Entity.Account.ID, partialAccounts: [Mastodon.Entity.PartialAccountWithAvatar]) {
            let authorHandle = partialAccounts.first(where: { $0.id == authorID })?.fullHandle ?? "someone@somewhere.social"
            let account = accountViewModels[authorID]?.account
            if let account {
                model.updateAuthorAccount(account)
            } else {
                model.authorHandle = "@" + authorHandle
            }
            model.updateAvatarUrls(partialAccounts)
        }
        func timelineItem(fromCollection collection: Mastodon.Entity.Collection, partialAccounts: [Mastodon.Entity.PartialAccountWithAvatar]) -> TimelineItem {
          
            let viewModel = {
                if let existing = collectionViewModels[collection.accountId] {
                    existing.updateCollection(collection)
                    updateCollectionModel(existing, withAuthorAccountID: collection.accountId, partialAccounts: partialAccounts)
                    return existing
                } else {
                    let model = CollectionViewModel(collection: collection)
                    updateCollectionModel(model, withAuthorAccountID: collection.accountId, partialAccounts: partialAccounts)
                    newCollectionModels[collection.id] = model
                    return model
                }
            }()
            return TimelineItem.collection(viewModel)
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
        func timelineItem(fromNewsLink link: Mastodon.Entity.Card) -> TimelineItem {
            return TimelineItem.link(link)
        }

        let newBatch: [TimelineItem]
        let newBatchBottomLoad: BottomLoad
        let newAsyncRefreshAvailable: Mastodon.Response.AsyncRefreshAvailable?
        func bottomLoad(fromLink link: Mastodon.Response.Link?) -> BottomLoad {
            if let url = link?.nextUrl {
                return .link(url)
            } else {
                return .nothingMoreToLoad
            }
        }
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
            newBatch = result.map { timelineItem(fromStatus:$0, isPinned: false) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
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
            newBatch = response.value.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
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
            newBatch = response.value.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
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
            let statuses = response.value.map { timelineItem(fromStatus: $0, isPinned: false) }
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
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
        case .collection(let collectionViewModel):
            let accountIDs = collectionViewModel.collection.items.compactMap { $0.account_id }
            let response = try await APIService.shared.accountsInfo(userIDs: accountIDs, authenticationBox: authenticatedUser)
            let accounts: [TimelineItem] = accountIDs.compactMap {
                guard let account = response[$0] else { return nil }
                return timelineItem(fromAccount: account, suggestedBecause: nil)
            }
            newBatch = accounts
            newBatchBottomLoad = .nothingMoreToLoad
            newAsyncRefreshAvailable = nil
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
                newBatch = response.value.map { timelineItem(fromStatus: $0, isPinned: false) }
                newBatchBottomLoad = bottomLoad(fromLink: response.link)
                newAsyncRefreshAvailable = response.asyncRefreshAvaliable
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
                newBatchBottomLoad = bottomLoad(fromLink: response.link)
                newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            case .news:
                let response = try await {
                    if let loadUrl {
                        return try await APIService.shared.links(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                    } else {
                        return try await APIService.shared.trendLinks(
                            domain: authenticatedUser.domain,
                            query: .init(offset: nil, limit: nil),
                            authenticationBox: authenticatedUser
                        )
                    }
                }()
                newBatch = response.value.map { timelineItem(fromNewsLink: $0) }
                newBatchBottomLoad = bottomLoad(fromLink: response.link)
                newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            case .forYou:
                let response = try await {
                    if let loadUrl {
                        return try await APIService.shared.suggestionAccounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                    } else {
                            return try await APIService.shared.suggestionAccountV2(
                                query: nil,
                                authenticationBox: authenticatedUser
                            )
                    }
                }()
               
                newBatch = response.value.map { suggestion in
                    let suggestedBecause = suggestion.sources ?? [suggestion.source].compactMap{$0}
                    return timelineItem(fromAccount: suggestion.account, suggestedBecause: suggestedBecause.isEmpty ? nil : suggestedBecause)
                }
                newBatchBottomLoad = bottomLoad(fromLink: response.link)
                newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            }
        case .linkMentions(let url):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.linkMentionsTimeline(
                        linkUrl: url,
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
        case .search(let searchModel):
            let trimmedSearchText = searchModel.trimmedSearchString
            if trimmedSearchText.isEmpty {
                newBatch = []
                newBatchBottomLoad = .nothingMoreToLoad
                newAsyncRefreshAvailable = nil
            } else {
                let query = Mastodon.API.V2.Search.Query(
                    q: trimmedSearchText,
                    type: searchModel.scope.searchType,
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
                let statuses = results.statuses.map { timelineItem(fromStatus: $0, isPinned: false) }
                let hashtags = results.hashtags.map { timelineItem(fromHashtag: $0) }
                let accounts = results.accounts.map { timelineItem(fromAccount: $0, suggestedBecause: nil) }
                newBatch = accounts + hashtags + statuses
                newBatchBottomLoad = bottomLoad(fromLink: response.link)
                newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            }
            
        case .userPosts(let userID, let queryFilter):
            let pinnedPosts = try await APIService.shared.userTimeline(
                accountID: userID,
                excludeReplies: queryFilter.excludeReplies,
                excludeReblogs: queryFilter.excludeReblogs,
                onlyMedia: queryFilter.onlyMedia,
                tagged: queryFilter.selectedHashtag?.name,
                pinnedOnly: true,
                authenticationBox: authenticatedUser
            ).value.filter { pinnedPost in
                switch queryFilter.filterType {
                case .mediaOnly:
                    let noMedia = pinnedPost.mediaAttachments?.isEmpty ?? true
                    return !noMedia
                case .userPosts, .unfilterable:
                    return true
                }
            }.filter { pinnedPost in
                if let selectedHashtag = queryFilter.selectedHashtag {
                    return pinnedPost.tags.contains { $0.name == selectedHashtag.name }
                } else {
                    return true
                }
            }.map { timelineItem(fromStatus: $0, isPinned: true) }
            
            let fullTimelineResponse = try await {
                if let loadUrl {
                    return try await APIService.shared.statuses(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.userTimeline(
                        accountID: userID,
                        excludeReplies: queryFilter.excludeReplies,
                        excludeReblogs: queryFilter.excludeReblogs,
                        onlyMedia: queryFilter.onlyMedia,
                        tagged: queryFilter.selectedHashtag?.name,
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            
            newBatch = (pinnedPosts.isEmpty ? [] : [TimelineItem.pinnedPosts(pinnedPosts)]) + fullTimelineResponse.value.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = bottomLoad(fromLink: fullTimelineResponse.link)
            newAsyncRefreshAvailable = fullTimelineResponse.asyncRefreshAvaliable
            
        case .featuredItems(let userID):
            // this only includes accounts because the featured hashtags are shown as filters at the top of the main activity tab
            let accountsResponse = try await {
                if let loadUrl {
                    return try await APIService.shared.accounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.featuredAccounts(userID: userID, maxID: nil, authenticationBox: authenticatedUser)
                }
            }()
            let accounts = accountsResponse.value.map { timelineItem(fromAccount: $0, suggestedBecause: nil) }
            let collections: [TimelineItem] = await {
                guard UserDefaults.standard.showCollections else { return [] }
                do {
                    let response = try await APIService.shared.collections(accountID: userID, authenticationBox: authenticatedUser)
                    let partialAccounts = response.value.partialAccounts ?? []
                    return response.value.collections.map { collection in
                        timelineItem(fromCollection: collection, partialAccounts: partialAccounts)
                    }
                } catch {
                    return []
                }
            }()
            newBatch = {
                return (accounts.isEmpty ? [] : ([.heading(L10nLookup.Scene.Profile.FeaturedTab.accountsHeading)] + accounts)) + (collections.isEmpty ? [] : ([.heading(L10nLookup.Scene.Profile.FeaturedTab.collectionsHeading)] + collections))
            }()
            newBatchBottomLoad = .nothingMoreToLoad
            newAsyncRefreshAvailable = nil
            
        case .accountsFollowed(let userId):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.accounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.following(userID: userId, maxID: nil, authenticationBox: authenticatedUser)
                }
            }()
            newBatch = response.value.map { timelineItem(fromAccount: $0, suggestedBecause: nil) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
        case .followers(let userId):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.accounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.followers(userID: userId, maxID: nil, authenticationBox: authenticatedUser)
                }
            }()
            newBatch = response.value.map { timelineItem(fromAccount: $0, suggestedBecause: nil) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
        case .familiarFollowers(let accountID):
            let response = try await {
                return try await APIService.shared.familiarFollowers(query: .init(ids: [accountID]), authenticationBox: authenticatedUser)
            }()
            newBatch = {
                guard let familiarFollowersList = response.value.first?.accounts else { return [] }
                return familiarFollowersList.map { timelineItem(fromAccount: $0, suggestedBecause: nil) }
            }()
            newBatchBottomLoad = .nothingMoreToLoad
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
        case .postHistory(let post):
            let response = try await APIService.shared.getHistory(forStatusID: post.id, authenticationBox: authenticatedUser)
            newBatch = response.value.enumerated().compactMap { (index, statusEdit) in timelineItem(fromStatusEdit: statusEdit, actualStatus: post, isOriginal: index == response.value.endIndex - 1) }
            newBatchBottomLoad = .nothingMoreToLoad
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
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
            let post = GenericMastodonPost.fromStatus(status, authenticatedDomain: authenticatedUser.domain)
            let response = try await APIService.shared.statusContext(
                statusID: status.id,
                authenticationBox: authenticatedUser
            )
            let context = response.value
            let threadModel = ThreadedConversationModel(threadContext: context, focusedPost: post)
            threadedConversationModel = threadModel
            newBatch = threadModel.fullThread.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = .nothingMoreToLoad  // pagination is not possible, only reloading
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
        case .thread(let root):
            let response = try await APIService.shared.statusContext(
                statusID: root.id,
                authenticationBox: authenticatedUser
            )
            let context = response.value
            let threadModel: ThreadedConversationModel
            if let basicPost = root as? MastodonBasicPost, let quote = basicPost.quotedPost, quote.fullPost == nil, quote.quotedPostID != nil {
                // likely this is a nested quote that is now being opened and therefore we should refetch the status in hopes of getting the full quoted status to display instead of the placeholder
                let refetchedStatus = try await APIService.shared.status(statusID: root.id, authenticationBox: authenticatedUser).value
                threadModel = ThreadedConversationModel(threadContext: context, focusedPost: GenericMastodonPost.fromStatus(refetchedStatus, authenticatedDomain: authenticatedUser.domain))
            } else {
                threadModel = ThreadedConversationModel(threadContext: context, focusedPost: root)
            }
            threadedConversationModel = threadModel
            newBatch = threadModel.fullThread.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = .nothingMoreToLoad  // pagination is not possible, only reloading
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
        case .myFollowedHashtags:
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.hashtags(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.getFollowedTags(
                        query: Mastodon.API.Account.FollowedTagsQuery(limit: nil),
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromHashtag: $0) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
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
            newBatch = response.value.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
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
            newBatch = response.value.map { timelineItem(fromStatus: $0, isPinned: false) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
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
            newBatch = response.value.map { timelineItem(fromAccount: $0, suggestedBecause: nil) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
        case .whoBoosted(let actionableStatusID):
            let response = try await {
                if let loadUrl {
                    return try await APIService.shared.accounts(fromUrl: loadUrl, authenticationBox: authenticatedUser)
                } else {
                    return try await APIService.shared.boostedBy(
                        actionableStatusID: actionableStatusID,
                        query: .init(maxID: nil, limit: nil),
                        authenticationBox: authenticatedUser
                    )
                }
            }()
            newBatch = response.value.map { timelineItem(fromAccount: $0, suggestedBecause: nil) }
            newBatchBottomLoad = bottomLoad(fromLink: response.link)
            newAsyncRefreshAvailable = response.asyncRefreshAvaliable
            
        case .notifications(scope: let scope):
            let response = try await {
                if let loadUrl {
                    return try await NotificationsLoader.getNotifications(fromUrl: loadUrl, scope: scope)
                } else {
                    return try await NotificationsLoader.getNotifications(withScope: scope, olderThan: nil, newerThan: nil)
                }
            }()
            newBatch = response.0.map { groupedNotificationInfo in
                if groupedNotificationInfo.groupedNotificationType.wantsFullStatusLayout, let post = groupedNotificationInfo.post {
                    return timelineItem(fromPost: post, isPinned: false, isOriginal: nil)
                } else {
                    let collectionID = groupedNotificationInfo.groupedNotificationType.attachedCollection?.id
                    let existingCollection: CollectionViewModel? = {
                        guard let collectionID else { return nil }
                        return collectionViewModels[collectionID] ?? newCollectionModels[collectionID]
                    }()
                    let notificationViewModel = {
                        if let existing = notificationViewModels[groupedNotificationInfo.id] {
                            existing.update(from: groupedNotificationInfo)
                            return existing
                        } else {
                            return NotificationRowViewModel(groupedNotificationInfo, myAccountDomain: authenticatedUser.domain, attachedCollection: existingCollection)
                        }
                    }()
                    if existingCollection == nil {
                        if let collectionID, let newCollectionModel = notificationViewModel.inlineCollectionViewModel {
                            newCollectionModels[collectionID] = newCollectionModel
                        }
                    } else if let collection = groupedNotificationInfo.groupedNotificationType.attachedCollection {
                        existingCollection?.updateCollection(collection)
                    }
                    newNotificationModels[groupedNotificationInfo.id] = notificationViewModel
                    return TimelineItem.notification(notificationViewModel)
                }
            }
            newBatchBottomLoad = bottomLoad(fromLink: response.1)
            newAsyncRefreshAvailable = response.2
            
        case .notificationRequests:
            let response = try await APIService.shared
                        .notificationRequests(authenticationBox: authenticatedUser)
            newBatch = response.value.compactMap { notificationRequest in
                return TimelineItem.notificationRequest(NotificationRequestModel(notificationRequest, authenticatedUser: authenticatedUser))
            }
            newBatchBottomLoad = .nothingMoreToLoad
            newAsyncRefreshAvailable = nil
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
        collectionViewModels = newCollectionModels
        notificationViewModels = newNotificationModels
        accountViewModels = newAccountModels
        hashtagViewModels = newHashtagModels
        createContentConcealViewModels(newCache)
        if let newAsyncRefreshAvailable {
            asyncRefreshViewModel?.beginPollingForResults(newAsyncRefreshAvailable, withSecondsBetweenButtonUpdate: 10, authenticationBox: authenticatedUser)
        }
        try? await fetchReplyTos(newCache)
        
        return newCache
    }
    
    override func filteredResults(fromCachedType cached: CacheableTimeline) -> [TimelineItem] {
        cached.filteredItems(inContext: timeline.filterContext)
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
        func includePostItem(_ postItem: TimelineItem) -> Bool {
            switch postItem {
            case .post(let postViewModel, _):
                if let contentPost = postViewModel.fullPost as? MastodonContentPost {
                    return !contentPost.content.shouldBeRemovedFromFeed(inContext: context)
                } else if let boost = postViewModel.fullPost as? MastodonBoostPost {
                    return !boost.boostedPost.content.shouldBeRemovedFromFeed(inContext: context)
                } else if let context {
                    return !postViewModel.initialDisplayInfo.filterOutInContexts.contains(context)
                } else {
                    return true
                }
            default:
                return false
            }
        }
        return items.compactMap { item -> TimelineItem? in
            switch item {
            case .heading, .loadingIndicator, .filteredNotificationsInfo:
                return item
            case .noItem:
                return nil
            case .post:
                return includePostItem(item) ? item : nil
            case .pinnedPosts(let postItems):
                let filteredItems = postItems.filter { includePostItem($0) }
                if filteredItems.isEmpty {
                    return nil
                } else {
                    return .pinnedPosts(filteredItems)
                }
            case .notification, .notificationRequest:
                return item
            case .hashtag, .link, .account, .collection:
                return item
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
                case .loadingIndicator, .filteredNotificationsInfo, .noItem, .heading: return false
                case .post, .pinnedPosts: return true
                case .notification, .notificationRequest: return true
                case .hashtag: return true
                case .link: return true
                case .account: return true
                case .collection: return true
                }
            })?.id
            
            if let oldestIdInNewBatch {
                let overlapIndex = older.firstIndex(where: { item in
                    switch item {
                    case .post:
                        return item.id == oldestIdInNewBatch
                    case .pinnedPosts:
                        return item.id == oldestIdInNewBatch
                    case .notification, .notificationRequest:
                        return item.id == oldestIdInNewBatch
                    case .hashtag:
                        return item.id == oldestIdInNewBatch
                    case .link:
                        return item.id == oldestIdInNewBatch
                    case .account:
                        return item.id == oldestIdInNewBatch
                    case .collection:
                        return item.id == oldestIdInNewBatch
                    case .heading, .loadingIndicator, .filteredNotificationsInfo, .noItem:
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
        let newItems = items.compactMap { item -> TimelineItem? in
            switch item {
            case .heading, .loadingIndicator, .filteredNotificationsInfo, .hashtag, .link, .account, .collection:
                return item
            case .post(let postViewModel, _):
                if postViewModel.fullPost?.actionablePost?.id != postId {
                    return item
                } else {
                    return nil
                }
            case .pinnedPosts(let postItems):
                let undeletedModels = postItems.filter {
                    switch $0 {
                    case .post(let postViewModel, _):
                        return postViewModel.fullPost?.actionablePost?.id != postId
                    default:
                        return false
                    }
                }
                if undeletedModels.isEmpty {
                    return nil
                } else {
                    return .pinnedPosts(undeletedModels)
                }
            case .notification, .notificationRequest:
                return item
            case .noItem:
                return nil
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
            assertionFailure("caching of timelines to disk has been disabled")
//            Task {
//                let timeline = BodegaPersistence.cachedTimeline(forUser: currentUser)
//                if trackLastRead {
//                    self.currentLastReadMarker = await BodegaPersistence.LastRead.lastReadMarkers(for: currentUser)?.lastRead(forKind: .home)
//                }
//                self.staleResults = CacheableTimeline(older: [], olderBottomLoad: .nothingMoreToLoad, newer: timeline, newerBottomLoad: .nothingMoreToLoad, discardOlderIfNoOverlap: false)
//            }
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
           // BodegaPersistence.cacheTimeline(items, forUser: currentUser)
            guard trackLastRead, let currentLastReadMarker else { return }
            Task {
                let currentMarkers = await BodegaPersistence.LastRead.lastReadMarkers(for: currentUser) ?? LastReadMarkers(userGUID: currentUser.globallyUniqueUserIdentifier, home: nil, notifications: nil, mentions: nil)
                try await BodegaPersistence.LastRead.saveLastReadMarkers(currentMarkers.bySettingPosition(currentLastReadMarker, forKind: .home, enforceForwardProgress: false), for: currentUser)
            }
        }
    }
    
    func clearCache() async {
        guard useDiskCache else { return }
      //  try? await BodegaPersistence.clearCachedTimeline(forUser: currentUser)
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
    
    func fetchRelationships(_ batch: [Mastodon.Entity.Account.ID]) async throws -> [String : MastodonAccount.Relationship] {
        guard !batch.isEmpty else { return [:] }
        
        let relationships = try await APIService.shared.relationship(forAccountIds: batch, authenticationBox: authenticatedUser)
        
        let currentTimestamp = Date.now
        var result = [String : MastodonAccount.Relationship]()

        for id in relationships.keys {
            guard id != myAccountID else { continue }
            guard let relationshipEntity = relationships[id] else { continue }
            let relationship = MastodonAccount.Relationship.isNotMe(MastodonAccount.RelationshipInfo(relationshipEntity, fetchedAt: currentTimestamp))
            cachedRelationships[id] = relationship
            result[id] = relationship
        }
        
        return result
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
            case .post(let postViewModel, _):
                return (postViewModel.fullPost as? MastodonBasicPost)?.inReplyTo?.accountID
            default:
                return nil
            }
        }
        
        let accounts = try await APIService.shared.accountsInfo(userIDs: accountsToFetch, authenticationBox: authenticatedUser)
        
        accountsCache.removeAll(keepingCapacity: true)
        for accountID in accounts.keys {
            guard let accountEntity = accounts[accountID] else { continue }
            accountsCache[accountID] = MastodonAccount.fromEntity(accountEntity, authenticatedDomain: authenticatedUser.domain)
        }
    }
}

// MARK: Filters and Content Warnings
extension TimelineFeedLoader {
    private func createContentConcealViewModels(_ cache: CacheableTimeline) {
        func create(forPostItem postItem: TimelineItem) {
            switch postItem {
            case .post(let postViewModel, _):
                if let contentPost = postViewModel.fullPost?.actionablePost, contentConcealViewModels[contentPost.id] == nil {
                    let model = ContentConcealViewModel(contentPost: contentPost, context: timeline.filterContext)
                    switch timeline {
                    case .postHistory:
                        if !model.currentMode.isShowingContent || !model.currentMode.isShowingMedia {
                            model.showMore() // note that this assumes filters will not be in use and this will unwrap the content warning/spoiler text
                        }
                        break
                    default:
                        break
                    }
                    contentConcealViewModels[contentPost.id] = model
                }
            default:
                assertionFailure()
                break
            }
        }
        for item in cache.items {
            switch item {
            case .heading, .loadingIndicator, .filteredNotificationsInfo, .hashtag, .link, .account, .noItem:
                break
            case .post:
                create(forPostItem: item)
            case .pinnedPosts(let postItems):
                for item in postItems {
                    create(forPostItem: item)
                }
            case .collection:
                break
            case .notification:
                // TODO: create conceal models for summarized statuses?
                break
            case .notificationRequest:
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
    
    static func getNotifications(withScope scope: NotificationsScope, olderThan: String? = nil, newerThan: String?) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?, Mastodon.Response.AsyncRefreshAvailable?) {
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
    
    static func getNotifications(fromUrl url: URL, scope: NotificationsScope) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?, Mastodon.Response.AsyncRefreshAvailable?) {
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
     
    static private func getNotifications(fromUrl url: URL, grouped: Bool) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?, Mastodon.Response.AsyncRefreshAvailable?) {
        let authenticationBox = try currentUser()
        
        if grouped {
            let response = try await APIService.shared.groupedNotifications(fromUrl: url, authenticationBox: authenticationBox)
            let infos = groupedNotificationInfos(fromGroupedNotifications: response.value, authenticationBox: authenticationBox)
            return (infos, response.link, response.asyncRefreshAvaliable)
        } else {
            let response = try await APIService.shared.ungroupedNotifications(fromUrl: url, authenticationBox: authenticationBox)
            let infos = groupedNotificationInfos(fromUngroupedNotifications: response.value, authenticationBox: authenticationBox)
            return (infos, response.link, response.asyncRefreshAvaliable)
        }
        
    }
    
    static private func getUngroupedNotifications(
        withScope scope: NotificationsScope, olderThan maxID: String? = nil, newerThan minID: String?
    ) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?, Mastodon.Response.AsyncRefreshAvailable?) {
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
        return (infos, response.link, response.asyncRefreshAvaliable)
    }
    
    static private func groupedNotificationInfos(fromUngroupedNotifications ungroupedNotifications: [Mastodon.Entity.Notification], authenticationBox: MastodonAuthenticationBox) -> [GroupedNotificationInfo] {
        return ungroupedNotifications.map { notification in
            let sourceAccounts = NotificationSourceAccounts(myAccountID: authenticationBox.domain, accounts: [notification.account], totalActorCount: 1)
            let notificationType = GroupedNotificationType(notification, myAccountDomain: authenticationBox.domain, sourceAccounts: sourceAccounts, adminReportID: nil)
            let navigation = NotificationRowViewModel.defaultNavigation(notificationType, isGrouped: false, primaryAccount: notification.account)
            let post = notification.status == nil ? nil : GenericMastodonPost.fromStatus(notification.status!, authenticatedDomain: authenticationBox.domain)
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
                group, myAccountDomain: authenticationBox.domain, sourceAccounts: sourceAccounts, status: status, collection: group.collection, adminReportID: group.adminReport?.id)
            
            let post = status == nil ? nil : GenericMastodonPost.fromStatus(status!, authenticatedDomain: authenticationBox.domain)
            
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
    ) async throws -> ([GroupedNotificationInfo], Mastodon.Response.Link?, Mastodon.Response.AsyncRefreshAvailable?) {
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
        
        return (groups, response.link, response.asyncRefreshAvaliable)
    }
    
}
