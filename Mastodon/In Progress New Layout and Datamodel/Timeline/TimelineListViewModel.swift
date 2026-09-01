// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import Combine
import UIKit
import MastodonCore
import MastodonSDK
import MastodonLocalization
import MastoParse
import MastodonUI

@MainActor
@Observable class TimelineListViewModel {
    
    private(set) var authenticatedUser: MastodonAuthenticationBox? = AuthenticationServiceProvider.shared.currentActiveUser.value
    private weak var navigator: MastodonNavigationRouter?
    
    var isCurrentlyOnScreen = false
    
    var unseenNewItemsCount: Int = 0 {
        didSet {
            if timeline.canDisplayUnreadNotifications
                && unseenNewItemsCount == 0
                && isCurrentlyOnScreen {
                guard let authentication = authenticatedUser?.authentication else { return }
                UnreadNotificationCounts.shared.setUnreadCount(0, for: authentication)
            }
        }
    }
    private(set) var waitingReplacementItems: [TimelineItem]?
    
    var presentedDonationCampaign: Mastodon.Entity.DonationCampaign?
    
    var isPresentingActivityFilter: Bool = false
    
    var pinnedPostsAreCollapsed: Bool = true
    
    var isPerformingPostAction: (action: MastodonPostMenuAction, post: MastodonContentPost)? = nil
    var isPerformingAccountAction: (action: MastodonPostMenuAction, account: MastodonAccount)? = nil
    
    var feedIsEmpty: Bool = false
    
    var familiarFollowers: TimelineListViewModel.FamiliarAccountsSummary?
    var currentDisplaySlice = ArraySlice<TimelineItem>()
    private(set) var currentUseableWidth: CGFloat?
    var scrollAnchorItem: TimelineItem = .noItem
    var scrollAnchorItemBinding: Binding<TimelineItem?> {
        Binding(get: {
            return self.scrollAnchorItem
        }, set: { newAnchorItem in
            guard let newAnchorItem else { self.scrollAnchorItem = .noItem; return }
            switch newAnchorItem {
            case .loadingIndicator:
                self.scrollAnchorItem = .noItem
            default:
                self.scrollAnchorItem = newAnchorItem
            }
        })
    }
    var isCurrentlyScrolling: Bool = false  // The interactive pop gesture (added by the system when this view is not the root view of the navigation controller) causes changes to the gesture recognition system that end up making it easy to trigger the action buttons while scrolling. Tracking the scroll phase allows us to avoid that.
    
    private var _updatedVisibleItems: [TimelineItem]?
    func visibleItemsDidChange(_ newVisibleItems: [TimelineItem]) {
        // This is required to correct for the fact that the system will not update the scrollPosition when the user taps the status bar to scroll all the way to the top, which will then cause the scroll to "restore" to the stale position if you navigate to another view and then come back to this one.
        _updatedVisibleItems = newVisibleItems
        DispatchQueue.main.async {
            guard let _updatedVisibleItems = self._updatedVisibleItems, let firstItem = self.currentDisplaySlice.first else { return }
            if _updatedVisibleItems.contains(firstItem) {
                if self.scrollAnchorItem.id != firstItem.id {
                    self.scrollAnchorItem = firstItem
                }
            }
        }
    }
    
    func updateUseableWidth(_ useableWidth: CGFloat) {
        let updatedUsableWidth = useableWidth
        if self.currentUseableWidth != updatedUsableWidth {
            self.currentUseableWidth = updatedUsableWidth
        }
    }
    
    func updateUnreadCount(scrollAnchor: TimelineItem) {
        if unseenNewItemsCount > 0 {
            if let indexOfNewScrollAnchor = currentDisplaySlice.firstIndex(of: scrollAnchor), indexOfNewScrollAnchor < unseenNewItemsCount {
                unseenNewItemsCount = indexOfNewScrollAnchor
            }
        }
    }
    
    let interactiveReloadTriggerModel = InteractiveLoadingTriggerModel()
    
    enum ReloadReason {
        case notificationFilterPolicyUpdated
        case userRequestedRefresh
        case notificationCountUpdated
        case asyncRefreshResultsRequested
        case activityFilterUpdated
        case mediaFilterUpdated
    }
    
    public var presentDonationDialog: ((Mastodon.Entity.DonationCampaign) -> ())?
    
    private var instanceConfigurationUpdateSubscription: AnyCancellable?
    
    var filteredNotificationsViewModel =
    FilteredNotificationsRowView.ViewModel(policy: nil)
    var needsReloadOnNextAppear = false
    var notificationRequestsAcceptanceDidChange = false
    
    // MARK - Sheets
    @ViewBuilder func activeSheetContents(_ activeSheet: MastodonTimelineSheet, navigator: MastodonNavigationRouter) -> some View {
        switch activeSheet {
        case .postInteractionSettingsEdit(let editModel):
            PostInteractionSettingsView(closeAndSave: { [weak self] save in
                if save {
                    Task {
                        do {
                            try await self?.commitCurrentQuotePolicyEdit(navigator: navigator)
                            self?.clearPendingActions(navigator)
                        } catch {
                            self?.clearPendingActions(navigator)
                            navigator.didReceiveError(error)
                        }
                    }
                } else {
                    self?.clearPendingActions(navigator)
                }
            })
            .environment(editModel)
            .presentationDetents([.fraction(0.5), .medium, .large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        case .boostOrQuoteDialog(let postViewModel):
            BoostOrQuoteDialog(actionHandler: self)
                .environment(postViewModel)
                .environment(navigator)
                .presentationDetents([.fraction(0.3), .medium, .large])
        case .manageListMembership(let account):
            let viewModel = MyListsManagementViewModel(account)
            ManageListMembershipView()
                .environment(viewModel)
                .environment(navigator)
        }
    }
    
    // MARK - Feed Contents
    func setCurrentDisplaySlice(_ newSlice: ArraySlice<TimelineItem>, newScrollAnchor: TimelineItem?, mayNeedHeightCalculations: Bool, addLoadingIndicator: Bool) {
        
        defer {
            switch loadingState {
            case .initializing:
                break
            default:
                interactiveReloadTriggerModel.reset(triggered: false)
            }
            
            switch timeline {
            case .familiarFollowers:
                familiarFollowers = familiarAccounts(maxCount: 3)
            default:
                break
            }
        }
        
        // space to add any necessary bookkeeping before setting the slice
        let prefix: [TimelineItem] = {
            switch timeline {
            case .notifications(.everything), .notifications(.mentions):
                if newSlice.startIndex == 0 {
                    return [.filteredNotificationsInfo(filteredNotificationsViewModel.policy, filteredNotificationsViewModel)]
                } else {
                    return []
                }
            default:
                return []
            }
        }()
        
        let suffix: [TimelineItem] = addLoadingIndicator ? [.loadingIndicator] : []
        if let newScrollAnchor {
            scrollAnchorItem = newScrollAnchor
            
            switch newScrollAnchor {
            case .post:
                let fullList = prefix + newSlice + suffix
                let split = fullList.split(maxSplits: 1, omittingEmptySubsequences: true) { item in
                    return item == newScrollAnchor
                }
                if !mayNeedHeightCalculations || split.count <= 1 {
                    currentDisplaySlice = fullList.prefix(fullList.count)
                    self.resetToUntrackedAfterDelay(from: loadingState)
                } else if let belowAnchor = split.last, let aboveSplit = split.first {
                    currentDisplaySlice = [newScrollAnchor] + belowAnchor
                    self.requestCalculateHeightsAndPrependToCurrentDisplay(aboveSplit)
                }
            case .pinnedPosts:
                // this should always be the very first item in the list, so we don't need to worry about calculating heights above
                fallthrough
            case .heading, .collection, .notification, .notificationRequest, .scopedSearchResults, .hashtag, .link, .account, .filteredNotificationsInfo, .loadingIndicator, .noItem:
                currentDisplaySlice = prefix + newSlice + suffix
                self.resetToUntrackedAfterDelay(from: loadingState)
            }
        } else {
            currentDisplaySlice = prefix + newSlice + suffix
            self.resetToUntrackedAfterDelay(from: loadingState)
        }
    }
    
    private var followersAndBlockedChangeSubscription: AnyCancellable?
    fileprivate var feedLoader: TimelineFeedLoader?
    private var feedLoaderResultsSubscription: AnyCancellable?
    private var feedLoaderErrorSubscription: AnyCancellable?
    private var notificationCountUpdateSubscription: AnyCancellable?
    
    private var currentlyPreparingForDisplay: [String]?
    private var displayPrepRequested: [MastodonPostViewModel]? // only keep the latest batch requested, to avoid getting bogged down while fast scrolling
    
    public var loadingState: LoadingState = .initializing
    
    public var threadedConversationModel: ThreadedConversationModel? {
        return feedLoader?.threadedConversationModel
    }
    
    // Translations
    private var translations = [ Mastodon.Entity.Status.ID : Mastodon.Entity.Translation]()
    
    func clearPendingActions(_ navigator: MastodonNavigationRouter?) {
        if isPerformingPostAction != nil {
            isPerformingPostAction = nil
        }
        if isPerformingAccountAction != nil {
            isPerformingAccountAction = nil
        }
        if navigator?.presentedSheet != nil {
            navigator?.presentedSheet = nil
        }
    }
    
    func commitToCache() {
        Task {
            await feedLoader?.commitToCache()
        }
    }
    
    private var _timeline: MastodonTimelineType
    public var timeline: MastodonTimelineType {
        _timeline
    }
    public func setTimeline(_ timeline: MastodonTimelineType, navigator: MastodonNavigationRouter) {
        _timeline = timeline
        guard feedLoader?.timeline != timeline else { return }
        feedLoader = nil
        feedLoaderErrorSubscription?.cancel()
        feedLoaderResultsSubscription?.cancel()
        loadingState = .untracked
        currentDisplaySlice = ArraySlice([.loadingIndicator])
        Task {
            try await doInitialLoad(navigator: navigator)
        }
    }
    
    private let _asyncRefreshViewModel: AsyncRefreshViewModel?
    public var asyncRefreshViewModel: AsyncRefreshViewModel? {
        return _asyncRefreshViewModel
    }
    
    init(timeline: MastodonTimelineType, navigator: MastodonNavigationRouter, asyncRefreshViewModel: AsyncRefreshViewModel?) {
        self._asyncRefreshViewModel = asyncRefreshViewModel
        self._timeline = timeline
        self.navigator = navigator
        
        self.instanceConfigurationUpdateSubscription = AuthenticationServiceProvider.shared.instanceConfigurationUpdates
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] updatedDomain in
                guard let self, self.authenticatedUser?.domain == updatedDomain else { return }
                self.authenticatedUser = AuthenticationServiceProvider.shared.currentActiveUser.value
            }
        
        Task {
            try await doInitialLoad(navigator: navigator)
        }
    }
    
    func setUpFeedLoaderResultsSubscription() {
        let subscriptionTimeline = feedLoader?.timeline
        feedLoaderResultsSubscription = feedLoader?.$records
            .sink{ [weak self] results in
                guard subscriptionTimeline == self?.timeline else { return }  // The notifications feedloader gets replaced when switching between Everything and Mentions. This makes sure not to mix lagging results from the previous selection before the old subscription gets canceled.
                
                guard results.allRecords.count > 0 || results.canLoadOlder else {
                    self?.feedIsEmpty = true
                    return
                }
                
                if self?.feedIsEmpty == true {
                    self?.feedIsEmpty = false
                }
                
                let needsPrep: [TimelineItem] = results.allRecords.compactMap { item -> TimelineItem? in
                    switch item {
                    case .heading, .loadingIndicator, .scopedSearchResults, .filteredNotificationsInfo, .notificationRequest, .hashtag, .link, .noItem:
                        return nil
                    case .account:
                        return item
                    case .collection:
                        return item
                    case .pinnedPosts:
                        let someModelNeedsPrep = {
                            for model in item.postViewModels {
                                if model.displayPrepStatus == .unprepared {
                                    return true
                                }
                            }
                            return false
                        }()
                        return someModelNeedsPrep ? item : nil
                    case .post(let postViewModel, _):
                        return postViewModel.displayPrepStatus == .unprepared ? item : nil
                    case .notification(let notificationViewModel):
                        return notificationViewModel.displayPrepStatus == .unprepared ? item : nil
                    }
                }
                
                func doTheDisplay() {
                    DispatchQueue.main.async {
                        self?.displayPreparedFeedloaderResults(items: results.allRecords, canLoadOlder: results.canLoadOlder)
                    }
                }
                if needsPrep.isEmpty {
                    doTheDisplay()
                } else {
                    self?.doPrepareForDisplay(needsPrep, completion: {
                        debugScroll("doPrepareForDisplay is done")
                        doTheDisplay()
                    })
                }
            }
    }
    
    func displayPreparedFeedloaderResults(items: [TimelineItem], canLoadOlder: Bool) {
        // first, ensure that the scrollAnchor is not the loadingIndicator
        switch self.scrollAnchorItem {
        case .noItem, .filteredNotificationsInfo:
            // the new items will appear scrolled to the top, which is correct
            break
        case .loadingIndicator:
            // if there was anything else in the feed, override this to be the last item before the loading indicator, to avoid jumping to the bottom of the new items
            if let indexOfLoadingIndicator = self.currentDisplaySlice.lastIndex(of: .loadingIndicator), indexOfLoadingIndicator > 0 {
                self.scrollAnchorItem = self.currentDisplaySlice[indexOfLoadingIndicator - 1]
            }
        default:
            // the new items will appear scrolled to this current item if possible, which is correct
            break
        }
        
        // now, figure out how to handle these new items
        let safeToSetNewItemsImmediately: Bool
        let newItemsCount: Int
        let newScrollAnchor: TimelineItem?
        switch self.loadingState {
        case .initializing:
            newScrollAnchor = nil // we will jump to the top of this brand new feed
            newItemsCount = 0 // ... so there will be no new items above the visible point
            safeToSetNewItemsImmediately = true
            
        case .requestedReloadFromTop, .requestedPrependedHeightCalculations, .untracked:
            // The new set of results may not include the current scroll anchor.  In that case, just show the new items snackbar and wait to do the actual reload (by tapping on the snackbar or doing a pull to refresh).
            let previousFirstItem = self.currentDisplaySlice.first(where: { $0.isRealItem })
            let currentFeedIsEmpty = previousFirstItem == nil
            
            let scrollPositionNeedNotOrCannotBePreserved = !self.timeline.canDisplayNewItemsSnackbar || self.scrollAnchorItem == .noItem || currentFeedIsEmpty
            safeToSetNewItemsImmediately = {
                if scrollPositionNeedNotOrCannotBePreserved {
                    return true
                } else if items.firstIndex(of: self.scrollAnchorItem) == nil {
                    return false
                } else {
                    return true
                }
            }()
            
            newScrollAnchor = nil // leave the scrollAnchor alone
            
            if scrollPositionNeedNotOrCannotBePreserved {
                newItemsCount = 0  // will jump to top
            } else {
                let indexItem = previousFirstItem ?? self.scrollAnchorItem // this will always be the previousFirstItem, because the current feed is not empty
                if let newIndexOfPreviousFirstItem = items.firstIndex(of: indexItem) {
                    newItemsCount = newIndexOfPreviousFirstItem
                } else if let newIndexOfScrollAnchor = items.firstIndex(of: self.scrollAnchorItem) {
                    // we may be missing an edge case here, where the first item in the old feed got deleted, but there is still overlap with the new feed.  in that case, this may overestimate the number of truly new items, but at least they will be items above the scrollAnchor
                    newItemsCount = newIndexOfScrollAnchor
                } else {
                    assert(!safeToSetNewItemsImmediately)
                    newItemsCount = items.count
                }
            }
            
        case .requestedAsyncRefreshResults:
            _asyncRefreshViewModel?.didRefreshFromOriginalEndpoint()
            fallthrough
        case .requestedReloadFromBottom:
            // leave the scrollPosition alone, it should work
            safeToSetNewItemsImmediately = true
            newScrollAnchor = nil
            newItemsCount = self.unseenNewItemsCount
        }
        
        // if this is a thread view, we might need to do the initial scroll to the focused post
        let initialThreadAnchorItem: TimelineItem? = {
            if let threadedModel = self.threadedConversationModel, !threadedModel.hasScrolledToFocusedPost {
                threadedModel.hasScrolledToFocusedPost = true
                return items.first(where: { item in
                    item.id.hasSuffix(threadedModel.focusedID)
                })
            } else {
                return nil
            }
        }()
        
        if timeline.canDisplayNewItemsSnackbar {
            self.unseenNewItemsCount = newItemsCount
        }
        
        if safeToSetNewItemsImmediately {
            self.resetToUntrackedAfterDelay(from: loadingState)
            self.setCurrentDisplaySlice(items.prefix(items.count), newScrollAnchor: initialThreadAnchorItem ?? newScrollAnchor, mayNeedHeightCalculations: true, addLoadingIndicator: canLoadOlder)
        } else {
            self.waitingReplacementItems = items
        }
    }
    
    func doInitialLoad(navigator: MastodonNavigationRouter) async throws {
        guard feedLoader == nil else { return }
        guard let authenticatedUser else { return }
        
        interactiveReloadTriggerModel.reset(triggered: true)
        
        interactiveReloadTriggerModel.onTrigger = {
            switch self.loadingState {
            case .initializing:
                return false
            case .untracked:
                self.loadMoreFromBottom()
                return true
            case .requestedPrependedHeightCalculations, .requestedReloadFromBottom, .requestedReloadFromTop, .requestedAsyncRefreshResults:
                return false
            }
        }
        
        clearPendingActions(nil)
        feedLoader = TimelineFeedLoader(currentUser: authenticatedUser, timeline: timeline, asyncRefreshViewModel: _asyncRefreshViewModel)
        
        setUpFeedLoaderResultsSubscription()
        
        feedLoaderErrorSubscription = feedLoader?.$currentError
            .receive(on: DispatchQueue.main)
            .sink { error in
                guard let error else { return }
                navigator.didReceiveError(error)
            }
        feedLoader?.doFirstLoad()
        
        if timeline.canDisplayUnreadNotifications {
            notificationCountUpdateSubscription = NotificationService.shared.unreadNotificationCountDidUpdate
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    if let authBox = self?.authenticatedUser,  UnreadNotificationCounts.shared.unreadCount(for: authBox) > 0 && self?.timeline.canDisplayUnreadNotifications == true {
                        if self?.isCurrentlyOnScreen == true {
                            Task {
                                await self?.forceReload(.notificationCountUpdated)
                            }
                        } else {
                            self?.needsReloadOnNextAppear = true
                        }
                    }
                }
        }
        
        followersAndBlockedChangeSubscription = AuthenticationServiceProvider.shared.$didChangeFollowersAndFollowing.sink {
            [weak self] userID in
            guard userID == self?.authenticatedUser?.globallyUniqueUserIdentifier else { return }
            guard let timeline = self?.timeline else { return }
            switch timeline {
            case .homeTimeline, .list, .featuredItems, .followers, .accountsFollowed, .familiarFollowers, .collection:
                self?.needsReloadOnNextAppear = true
            case .myBookmarks, .myFavorites, .myFollowedHashtags, .local, .hashtag, .linkMentions, .discover, .search, .userPosts, .postHistory, .thread, .remoteThread, .notifications, .notificationRequests, .whoFavourited, .whoBoosted:
                return
            }
        }
    }
    
    func loadMoreFromBottom() {
        guard let feedLoader else {
            // this is a valid state when switching between timelines
            resetToUntrackedAfterDelay(from: loadingState)
            return
        }
        loadingState = .requestedReloadFromBottom
        feedLoader.requestLoad(.older)
    }
    
    func refreshFromTop() async {
        assert(loadingState == .requestedReloadFromTop, "Caller must synchronously set loading state before requesting async reload.")
        if let waiting = waitingReplacementItems, !waiting.isEmpty {
            scrollToTop()
        } else {
            await _refreshFromTop()
        }
        resetToUntrackedAfterDelay(from: loadingState)
    }
    
    private func _refreshFromTop() async {
        assert(loadingState == .requestedReloadFromTop)
        await forceReload(.userRequestedRefresh)
    }
    
    func reload() async {
        guard let feedLoader else {
            resetToUntrackedAfterDelay(from: loadingState)
            assertionFailure()
            return
        }
        needsReloadOnNextAppear = false
        feedLoader.requestLoad(.reload)
    }
    
    func forceReload(_ reason: ReloadReason) async {
        guard let feedLoader else {
            resetToUntrackedAfterDelay(from: loadingState)
            assertionFailure()
            return
        }
        needsReloadOnNextAppear = false
        switch reason {
        case .notificationCountUpdated:
            loadingState = .requestedReloadFromTop
            feedLoader.requestLoad(.reload)
        case .notificationFilterPolicyUpdated:
            loadingState = .requestedReloadFromTop
            feedLoader.requestLoad(.reload)
        case .activityFilterUpdated, .mediaFilterUpdated:
            loadingState = .initializing
            interactiveReloadTriggerModel.reset(triggered: true)
            feedLoader.requestLoad(.reloadForFilterChange)
        case .asyncRefreshResultsRequested:
            loadingState = .requestedAsyncRefreshResults
            feedLoader.requestLoad(.reload)
        case .userRequestedRefresh:
            if timeline.canDisplayFilteredNotifications {
                MastodonTabViewRouter.current.fetchFilteredNotificationsPolicy(andReloadFeed: false)
            }
            if await feedLoader.loadImmediatelyIfPossible(.reload) {
                await feedLoader.clearCache() // reset the cache when user refreshes
                commitToCache()
            }
        }
    }
    
    func scrollToTop() {
        if let waitingReplacementItems, !waitingReplacementItems.isEmpty {
            self.waitingReplacementItems = nil
            setCurrentDisplaySlice(waitingReplacementItems.prefix(waitingReplacementItems.count), newScrollAnchor: waitingReplacementItems.first ?? .noItem, mayNeedHeightCalculations: false, addLoadingIndicator: true)
        } else {
            scrollAnchorItem = currentDisplaySlice.first ?? .noItem
        }
    }
    
    func myRelationship(to account: MastodonAccount?)
    -> MastodonAccount.Relationship
    {
        guard let account else { return .isNotMe(nil)}
        return feedLoader?.myRelationship(to: account.id) ?? .isNotMe(nil)
    }
    
    func contentConcealModel(forActionablePost post: Mastodon.Entity.Status.ID) -> ContentConcealViewModel {
        return feedLoader?.contentConcealViewModel(forContentPost: post) ?? .alwaysShow
    }
}

extension TimelineListViewModel {
    var timelineQueryFilter: TimelineQueryFilter? {
        switch timeline {
        case .userPosts(_, let queryFilter):
            queryFilter
        default:
            TimelineQueryFilter(.unfilterable)
        }
    }
    
    var includeBoosts: Bool {
        get {
            !(timelineQueryFilter?.excludeReblogs ?? false)
        }
        set {
            let updatedValue = !newValue
            if timelineQueryFilter?.excludeReblogs != updatedValue {
                timelineQueryFilter?.excludeReblogs = updatedValue
                Task {
                    await forceReload(.activityFilterUpdated)
                }
            }
        }
    }
    
    var includeReplies: Bool {
        get {
            !(timelineQueryFilter?.excludeReplies ?? true)
        }
        set {
            let updatedValue = !newValue
            if timelineQueryFilter?.excludeReplies != updatedValue {
                timelineQueryFilter?.excludeReplies = updatedValue
                Task {
                    await forceReload(.activityFilterUpdated)
                }
            }
        }
    }
    
    var activityFilterButtonTitle: String {
        switch (includeBoosts, includeReplies) {
        case (true, true):
            return L10nLookup.Scene.Profile.ActivityFilter.includeBoostsAndReplies
        case (false, false):
            return L10nLookup.Scene.Profile.ActivityFilter.directPostsOnly
        case (false, true):
            return L10nLookup.Scene.Profile.ActivityFilter.includeReplies
        case (true, false):
            return L10nLookup.Scene.Profile.ActivityFilter.includeBoosts
        }
    }
}

extension TimelineListViewModel {
    
    func requestCalculateHeightsAndPrependToCurrentDisplay(_ items: ArraySlice<TimelineItem>) {
        let token = UUID()
        loadingState = .requestedPrependedHeightCalculations(token)
        let toCalculate = items.compactMap({ item in
            switch item {
            case .post(let viewModel, let isPinned):
                return (viewModel, isPinned)
            default:
                assertionFailure("precalculating height is not supported for \(item.id)")
                return nil
            }
        })
        Task {
            for (model, isPinned) in toCalculate {
                await calculateHeight(model, isPinned: isPinned)
            }
            let calculatedItems = toCalculate.map { (model, isPinned) in
                TimelineItem.post(model, isPinned: isPinned)
            }
            switch loadingState {
            case .requestedPrependedHeightCalculations(token):
                setCurrentDisplaySlice(calculatedItems + currentDisplaySlice, newScrollAnchor: nil, mayNeedHeightCalculations: false, addLoadingIndicator: false)
            default:
                assertionFailure("outran the height calculations. \(calculatedItems.count) items may never be added to the display")
                break
            }
        }
    }
    
    func calculateHeight(_ model: MastodonPostViewModel, isPinned: Bool) async {
        guard let currentUseableWidth else { return }
        let contentWidth = contentWidth(forUseableWidth: currentUseableWidth)
        let height = await ViewMeasurer.shared.calculateHeight(for: model, isPinned: isPinned, contentConcealModel: contentConcealModel(forActionablePost: model.initialDisplayInfo.actionablePostID), filterContext: timeline.filterContext, threadedContext: threadedConversationModel?.context(for: model.initialDisplayInfo.id), contentWidth: contentWidth, totalWidth: currentUseableWidth, actionHandler: self)
        model.precalculatedHeights.insert(height, at: 0)
    }
    
}

extension TimelineListViewModel {
    func updateFilteredNotificationsPolicy(
        _ policy: Mastodon.Entity.NotificationPolicy?,
        andReloadFeed reload: Bool
    ) {
        guard filteredNotificationsViewModel.policy != policy else { return }
        filteredNotificationsViewModel.policy = policy
        guard reload else { return }
        
        switch loadingState {
        case .initializing:
            break
        case .requestedReloadFromTop, .requestedReloadFromBottom, .requestedPrependedHeightCalculations, .requestedAsyncRefreshResults:
            break
        case .untracked:
            Task {
                await self.forceReload(.notificationFilterPolicyUpdated)
            }
        }
    }
}

extension TimelineListViewModel {
    
    private func doPrepareForDisplay(_ batch: [TimelineItem], completion: (()->())? = nil) {
        guard let feedLoader else { completion?(); return }
        guard currentlyPreparingForDisplay == nil else { completion?(); return }
        currentlyPreparingForDisplay = batch.compactMap { item in
            switch item {
            case .post:
                return item.id
            case .pinnedPosts:
                return item.id
            case .notification:
                return item.id
            case .hashtag, .link:
                return nil
            case .account:
                return item.id
            case .collection:
                return nil
            case .filteredNotificationsInfo, .notificationRequest, .loadingIndicator, .scopedSearchResults, .noItem, .heading:
                return nil
            }
        }
        
        var needsPrep = [MastodonPostViewModel]()
        var accountsToFetch = Set<Mastodon.Entity.Account.ID>()
        var relationshipsToFetch = Set<Mastodon.Entity.Account.ID>()
        
        func processPostViewModel(_ postViewModel: MastodonPostViewModel) {
            if postViewModel.initialDisplayInfo.actionableAuthorId == authenticatedUser?.userID {
                postViewModel.prepareForDisplay(relationship: .isMe, theirAccountIsLocked: false) // locked doesn't matter in this case
            } else {
                relationshipsToFetch.insert(postViewModel.initialDisplayInfo.actionableAuthorId)
            }
            if let actionablePost = postViewModel.fullPost?.actionablePost, postViewModel.isShowingTranslation == nil {
                postViewModel.isShowingTranslation = canTranslate(post: actionablePost) ? false : nil
            }
        }
        
        func processCollectionModel(_ collectionModel: CollectionViewModel) {
            accountsToFetch.insert(collectionModel.collection.accountId)
            relationshipsToFetch.insert(collectionModel.collection.accountId)
            for includedAccount in collectionModel.collection.items.prefix(4) {
                if let accountID = includedAccount.account_id {
                    accountsToFetch.insert(accountID)
                }
            }
        }
        
        for item in batch {
            switch item {
            case .pinnedPosts:
                for postModel in item.postViewModels {
                    if postModel.displayPrepStatus == .unprepared {
                        needsPrep.append(postModel)
                    }
                    if let fullQuotedPostViewModel = postModel.fullQuotedPostViewModel {
                        needsPrep.append(fullQuotedPostViewModel)
                    }
                }
            case .post(let postModel, _):
                if postModel.displayPrepStatus == .unprepared {
                    needsPrep.append(postModel)
                }
                if let fullQuotedPostViewModel = postModel.fullQuotedPostViewModel {
                    needsPrep.append(fullQuotedPostViewModel)
                }
                if let collectionModel = postModel.collectionViewModel {
                    processCollectionModel(collectionModel)
                }
            case .notification(let notificationViewModel):
                if let embeddedPostModel = notificationViewModel.inlinePostViewModel {
                    needsPrep.append(embeddedPostModel)
                    if let fullQuotedPostViewModel = embeddedPostModel.fullQuotedPostViewModel {
                        needsPrep.append(fullQuotedPostViewModel)
                    }
                }
                if let needsRelationshipTo = notificationViewModel.needsRelationshipTo {
                    relationshipsToFetch.insert(needsRelationshipTo.id)
                }
                if let embeddedCollectionViewModel = notificationViewModel.inlineCollectionViewModel {
                    for accountId in embeddedCollectionViewModel.collection.items.prefix(4).compactMap({ $0.account_id}) {
                        accountsToFetch.insert(accountId)
                    }
                }
            case .account(let accountRowViewModel):
                relationshipsToFetch.insert(accountRowViewModel.id)
            case .hashtag, .link:
                break
            case .collection(let collectionViewModel):
                processCollectionModel(collectionViewModel)
            case .heading, .filteredNotificationsInfo, .notificationRequest, .scopedSearchResults, .loadingIndicator, .noItem:
                break
            }
        }
        
        for postModel in needsPrep {
            processPostViewModel(postModel)
        }
        
        let toPrep = needsPrep
        let _relationshipsToFetch = relationshipsToFetch
        let _accountsToFetch = accountsToFetch
        
        guard let authenticatedUser else { return }
        Task {
            defer {
                currentlyPreparingForDisplay = nil
                completion?()
            }
            
            do {
                let fetchedAccountsDict = try await APIService.shared.accountsInfo(userIDs: Array(_accountsToFetch), authenticationBox: authenticatedUser)
                let fetchedRelationships = try await feedLoader.fetchRelationships(Array(_relationshipsToFetch))
                let fetchedAccounts = _accountsToFetch.compactMap { fetchedAccountsDict[$0] }
                
                @MainActor
                func updateCollectionModel(_ collectionModel: CollectionViewModel) {
                    if let account = fetchedAccountsDict[collectionModel.collection.accountId] {
                        collectionModel.updateAuthorAccount(MastodonAccount.fromEntity(account, authenticatedDomain: authenticatedUser.domain))
                    }
                    if let relationship = fetchedRelationships[collectionModel.collection.accountId] {
                        collectionModel.prepareForDisplay(withRelationship: relationship)
                    }
                    collectionModel.updateAvatarUrls(fetchedAccounts)
                }
                
                for postModel in toPrep {
                    if postModel.fullPost?.actionablePost?.metaData.author.id == authenticatedUser.userID {
                        postModel.prepareForDisplay(relationship: .isMe, theirAccountIsLocked: postModel.fullPost?.actionablePost?.metaData.author.locked ?? false)
                    } else {
                        let relationship = fetchedRelationships[postModel.initialDisplayInfo.actionableAuthorId] ?? feedLoader.myRelationship(to: postModel.initialDisplayInfo.actionableAuthorId)
                        
                        postModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: postModel.fullPost?.actionablePost?.metaData.author.locked ?? false)
                    }
                    if let collectionViewModel = postModel.collectionViewModel {
                        updateCollectionModel(collectionViewModel)
                    }
                    postModel.displayPrepStatus = .donePreparing
                }
                
                for item in batch {
                    switch item {
                    case .notification(let notificationViewModel):
                        let accountRelatingTo = notificationViewModel.needsRelationshipTo
                        if let id = accountRelatingTo?.id, let relationship = fetchedRelationships[id] {
                            notificationViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: accountRelatingTo?.locked ?? false)
                        }
                        notificationViewModel.actionHandler = self
                        notificationViewModel.displayPrepStatus = .donePreparing
                        if let collectionModel = notificationViewModel.inlineCollectionViewModel {
                            updateCollectionModel(collectionModel)
                        }
                    case .account(let accountViewModel):
                        if let relationship = fetchedRelationships[accountViewModel.id] {
                            if accountViewModel.actionHandler == nil {
                                accountViewModel.actionHandler = self
                            }
                            accountViewModel.prepareForDisplay(withRelationship: relationship)
                        } else if accountViewModel.id == AuthenticationServiceProvider.shared.currentActiveUser.value?.userID {
                            accountViewModel.prepareForDisplay(withRelationship: .isMe)
                        }
                    case .post, .pinnedPosts:
                        // handled above
                        break
                    case .hashtag, .link:
                        break
                    case .collection(let collectionViewModel):
                        updateCollectionModel(collectionViewModel)
                    case .heading, .filteredNotificationsInfo, .notificationRequest, .loadingIndicator, .scopedSearchResults, .noItem:
                        break
                    }
                }
            } catch {
                navigator?.didReceiveError(error)
            }
        }
    }
}

extension TimelineListViewModel {
    enum LoadingState: Equatable {
        case initializing
        case untracked
        case requestedPrependedHeightCalculations(UUID)
        case requestedReloadFromBottom
        case requestedReloadFromTop
        case requestedAsyncRefreshResults
        
        var canReload: Bool {
            switch self {
            case .untracked:
                true
            default:
                false
            }
        }
    }
    
    func resetToUntrackedAfterDelay(from currentState: LoadingState) {
        debugScroll("will reset to untracked")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            // the delay prevents loads immediately triggering new loads.
            // the state check prevents state races, especially when preparing precalculated heights.
            guard currentState == self.loadingState else { return }
            self.loadingState = .untracked
            debugScroll("did reset to untracked")
        }
    }
}

extension TimelineListViewModel {
    func askForDonationIfPossible() async {
        guard timeline == .homeTimeline else { return }
        guard let authenticatedUser else { return }
        guard let accountCreatedAt = authenticatedUser.authentication.accountCreatedAt else {
            let updated = try? await APIService.shared.verifyAndActivateUser(domain: authenticatedUser.domain,
                                                                             clientID: authenticatedUser.authentication.clientID,
                                                                             clientSecret: authenticatedUser.authentication.clientSecret,
                                                                             authorization: authenticatedUser.userAuthorization)
            guard let accountCreatedAt = updated?.1.authentication.createdAt else { return }
            AuthenticationServiceProvider.shared.updateAccountCreatedAt(accountCreatedAt, forAuthentication: authenticatedUser.authentication)
            return
        }
        
        guard
            Mastodon.Entity.DonationCampaign.isEligibleForDonationsBanner(
                domain: authenticatedUser.domain,
                accountCreationDate: accountCreatedAt)
        else { return }
        
        let seed = Mastodon.Entity.DonationCampaign.donationSeed(
            username: authenticatedUser.authentication.username,
            domain: authenticatedUser.domain)
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            
            do {
                let campaign = try await APIService.shared
                    .getDonationCampaign(seed: seed, source: .banner).value
                guard !Mastodon.Entity.DonationCampaign.hasPreviouslyDismissed(campaign.id) && !Mastodon.Entity.DonationCampaign.hasPreviouslyContributed(campaign.id) else { return }
                presentedDonationCampaign = campaign
            } catch {
                // no-op
            }
        }
    }
}

extension TimelineListViewModel: MastodonPostMenuActionHandler {
    
    func publishUpdate(_ update: UpdatedElement) {
        FeedCoordinator.shared.publishUpdate(update)
    }
    
    func vote(poll: MastodonSDK.Mastodon.Entity.Poll, choices: [Int], containingPostID: Mastodon.Entity.Status.ID) async throws -> Mastodon.Entity.Poll {
        guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
        let updatedPoll = try await APIService.shared.vote(poll: poll, choices: choices, authenticationBox: authenticatedUser).value
        let updatedContainingStatus = try await APIService.shared.status(statusID: containingPostID, authenticationBox: authenticatedUser).value
        publishUpdate(.post(GenericMastodonPost.fromStatus(updatedContainingStatus, authenticatedDomain: authenticatedUser.domain)))
        return updatedPoll
    }
    
    var containerOverlayBinding: Binding<MastodonFadeInOverlay?> {
        Binding<MastodonFadeInOverlay?>(
            get: { MastodonTabViewRouter.current.activeOverlay },
            set: { newValue in MastodonTabViewRouter.current.setActiveOverlay(newValue, animated: true) }
        )
    }
    
    func account(_ id: Mastodon.Entity.Account.ID) -> MastodonAccount? {
        return feedLoader?.account(id)
    }
    
    func currentRelationship(to account: Mastodon.Entity.Account.ID) -> MastodonAccount.Relationship? {
        return feedLoader?.myRelationship(to: account)
    }
    
    func doAction(_ action: MastodonPostMenuAction, forPost postViewModel: MastodonPostViewModel, navigator: MastodonNavigationRouter) {
        
        guard !isCurrentlyScrolling else { return }
        
        // Check not currently performing an action.
        guard isPerformingPostAction == nil && isPerformingAccountAction == nil else { return }
        
        guard let authenticatedUser, let actionablePost = postViewModel.fullPost?.actionablePost else { return }
        
        let author = actionablePost.metaData.author
        
        // Inform of what action is being done. These are cleared upon success or error, and in onAppear() of the view.
        if action.updatesMyActionsOnPost {
            self.isPerformingPostAction = (action, actionablePost)
        } else if action.updatesMyRelationshipToAuthor {
            self.isPerformingAccountAction = (action, author)
        }
        
        Task {
            do {
                switch action {
                    
                    // MARK: ACTION BAR
                case .reply:
                    let statusEntityToReplyTo = try await APIService.shared.status(statusID: actionablePost.id, authenticationBox: authenticatedUser).value
                    let composeViewModel = ComposeViewModel(
                        authenticationBox: authenticatedUser,
                        composeContext: .composeStatus(quoting: nil),
                        destination: .reply(parent: MastodonStatus(entity: statusEntityToReplyTo, showDespiteContentWarning: true)),
                        completion: { outcome in
                            switch outcome {
                            case .success:
                                // refetch this post to update the reply button
                                self.refetchAndDisplay(actionablePostID: actionablePost.id)
                            case .failure:
                                break
                            case .cancelled:
                                break
                            }
                        }
                    )
                    navigator.presentSheet(.modalCompose(composeViewModel, nil), afterDeconflictionDelay: true)
                case .boost:
                    Task {
                        let canDoQuotePosts = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.quotePosts) ?? false
                        await boost(actionablePost.id, askFirst: !canDoQuotePosts && UserDefaults.standard.askBeforeBoostingAPost, navigator: navigator)
                    }
                case .unboost, .favourite, .unfavourite, .bookmark, .unbookmark:
                    let updated: Mastodon.Entity.Status?
                    switch action {
                    case .unboost:
                        updated = try await APIService.shared.unboost(boostableStatusId: actionablePost.id, authenticationBox: authenticatedUser)
                    case .favourite:
                        updated = try await APIService.shared.favourite(actionableStatusID: actionablePost.id, authenticationBox: authenticatedUser)
                    case .unfavourite:
                        updated = try await APIService.shared.unfavourite(actionableStatusId: actionablePost.id, authenticationBox: authenticatedUser)
                    case .bookmark:
                        updated = try await APIService.shared.bookmark(actionableStatusId: actionablePost.id, authenticationBox: authenticatedUser)
                    case .unbookmark:
                        updated = try await APIService.shared.unbookmark(actionableStatusId: actionablePost.id, authenticationBox: authenticatedUser)
                    default:
                        assertionFailure("not implemented")
                        updated = nil
                    }
                    if let updated {
                        publishUpdate(.post(GenericMastodonPost.fromStatus(updated, authenticatedDomain: authenticatedUser.domain)))
                    }
                    clearPendingActions(navigator)
                    
                    // MARK: TRANSLATE
                case .translatePost:
                    try await getTranslation(forPost: actionablePost)
                    feedLoader?.updateCachedResults({ timeline in
                        for item in timeline.items {
                            switch item {
                            case .heading, .loadingIndicator, .filteredNotificationsInfo, .scopedSearchResults, .hashtag, .link, .noItem:
                                break
                            case .pinnedPosts:
                                for viewModel in item.postViewModels {
                                    if viewModel.fullPost?.actionablePost?.id == actionablePost.id {
                                        viewModel.isShowingTranslation = true
                                    }
                                }
                            case .post(let viewModel, _):
                                if viewModel.fullPost?.actionablePost?.id == actionablePost.id {
                                    viewModel.isShowingTranslation = true
                                }
                            case .notification, .notificationRequest, .account, .collection:
                                break
                            }
                        }
                    })
                case .showOriginalLanguage:
                    feedLoader?.updateCachedResults({ timeline in
                        for item in timeline.items {
                            switch item {
                            case .heading, .loadingIndicator, .filteredNotificationsInfo, .scopedSearchResults, .hashtag, .link, .noItem:
                                break
                            case .pinnedPosts:
                                for viewModel in item.postViewModels {
                                    if viewModel.fullPost?.actionablePost?.id == actionablePost.id {
                                        viewModel.isShowingTranslation = false
                                    }
                                }
                            case .post(let viewModel, _):
                                if viewModel.fullPost?.actionablePost?.id == actionablePost.id {
                                    viewModel.isShowingTranslation = false
                                }
                            case .notification, .notificationRequest, .account, .collection:
                                break
                            }
                        }
                    })
                    
                    // MARK: EDIT
                case .editPost:
                    let statusEntityToEdit = try await APIService.shared.status(statusID: actionablePost.id, authenticationBox: authenticatedUser).value
                    let statusSourceToEdit = try await APIService.shared.getStatusSource(
                        forStatusID: actionablePost.id,
                        authenticationBox: authenticatedUser
                    ).value
                    
                    let editStatusViewModel = ComposeViewModel(
                        authenticationBox: authenticatedUser,
                        composeContext: .editStatus(status: statusEntityToEdit, statusSource: statusSourceToEdit, quoting: {
                            if let quotedPostViewModel = postViewModel.fullQuotedPostViewModel {
                                AnyView(
                                    EmbeddedPostView(layoutWidth: 200, isSummary: false, actionHandler: nil, accountLinkHandler: nil, linkTapPolicy: .forceSystemBrowserRegardlessOfUserPreference)
                                        .environment(quotedPostViewModel)
                                        .environment(TimestampUpdater.timestamper(withInterval: 30))
                                        .environment(ContentConcealViewModel.alwaysShow)
                                    
                                )
                            } else {
                                AnyView(EmptyView())
                            }
                        }),
                        destination: .topLevel, completion: { outcome in
                            switch outcome {
                            case .success:
                                // refetch the post to display the edits
                                self.refetchAndDisplay(actionablePostID: statusEntityToEdit.id)
                            case .failure, .cancelled:
                                break
                            }
                        })
                    navigator.presentSheet(.modalCompose(editStatusViewModel, nil), afterDeconflictionDelay: true)
                    
                case .changeQuotePolicy:
                    let activeSheet = MastodonTimelineSheet.postInteractionSettingsEdit(
                        PostInteractionSettingsViewModel(
                            account: actionablePost.metaData.author._legacyEntity,
                            initialSettings:
                                    .editing(
                                        visibility: actionablePost._legacyEntity.visibility ?? .public,
                                        quotability: actionablePost._legacyEntity.specifiedQuotePolicyOrNobody
                                    ),
                            contentIncludesQuote: postViewModel.fullQuotedPostViewModel != nil || postViewModel.placeholderQuotedPost != nil
                        )
                    )
                    navigator.presentedSheet = .timelineSheet(activeSheet)
                    
                    // MARK: POST ACTIONS
                case .copyLinkToPost:
                    guard let urlString = actionablePost.metaData.url else { throw PostActionFailure.noActionablePostId }
                    UIPasteboard.general.string = urlString
                    
                case .copyOriginalText:
                    let string = {
                        if let plainString = actionablePost.content.plainText {
                            return plainString
                        }
                        if let htmlString = actionablePost.content.htmlWithEntities?.html {
                            return plainText(from: htmlString)
                        } else {
                            return ""
                        }
                    }()
                    UIPasteboard.general.string = string
                    
                case .copyTranslatedText:
                    let string = {
                        if let translationHtml = translations[actionablePost.id]?.content {
                            return plainText(from: translationHtml)
                        } else if let string = actionablePost.content.plainText {
                            return string
                        } else if let htmlString = actionablePost.content.htmlWithEntities?.html {
                            return plainText(from: htmlString)
                        } else {
                            return ""
                        }
                    }()
                    UIPasteboard.general.string = string
                    
                case .openPostInBrowser:
                    guard let urlString = actionablePost.metaData.url, let url = URL(string: urlString) else { throw PostActionFailure.noActionablePostId }
                    let result = navigator.openUrl(url, afterDeconflictionDelay: false, forceInBrowser: true)
                    result.completeIfNeeded()
                    
                case .sharePost:
                    assertionFailure("The share option should be rendered by a ShareLink")
                    break
                    
                    // MARK: RELATIONSHIP ACTIONS
                    
                case .follow, .unfollow, .mute, .unmute, .blockUser, .unblockUser:
                    try await doAction(action, forAccount: author, relationshipViewModel: postViewModel.myRelationshipToAuthorViewModel, navigator: navigator)
                    isPerformingAccountAction = nil
                    
                    // MARK: DEFENSIVE ACTIONS
                case .removeQuote:
                    try await doRemoveQuote(from: actionablePost, askFirst: true, navigator: navigator)
                    
                case .reportPost:
                    guard let relationship = try await APIService.shared.relationship(forAccountIds: [author.id], authenticationBox: authenticatedUser)[author.id] else { throw PostActionFailure.noRelationshipInfo }
                    let accountToReport = try await APIService.shared.accountInfo(domain: authenticatedUser.domain, userID: author.id, authorization: authenticatedUser.userAuthorization)
                    
                    let statusEntity: Mastodon.Entity.Status?
                    statusEntity = try? await APIService.shared.status(statusID: actionablePost.id, authenticationBox: authenticatedUser).value
                    
                    let reportViewModel = ReportViewModel(
                        context: AppContext.shared,
                        authenticationBox: authenticatedUser,
                        account: accountToReport,
                        relationship: relationship,
                        status: statusEntity == nil ? nil : MastodonStatus(entity: statusEntity!, showDespiteContentWarning: true),
                        collection: nil
                    )
                    navigator.presentSheet(.report(reportViewModel), afterDeconflictionDelay: true)
                    
                    // MARK: DELETE
                case .deletePost:
                    await deletePost(actionablePost.id, askFirst: UserDefaults.shared.askBeforeDeletingAPost, navigator: navigator)
                }
            } catch {
                navigator.didReceiveError(error)
                assertionFailure()
                clearPendingActions(navigator)
            }
        }
    }
    
    func commitCurrentQuotePolicyEdit(navigator: MastodonNavigationRouter) async throws {
        guard let (action, post) = isPerformingPostAction, action == .changeQuotePolicy, let authBox = AuthenticationServiceProvider.shared.currentActiveUser
            .value, case let .timelineSheet(.postInteractionSettingsEdit(editModel)) = navigator.presentedSheet else { throw PostActionFailure.unsupportedAction }
        Task {
            do {
                let updated = try await APIService.shared.updateQuotePolicy(forStatus: post.id, to: editModel.interactionSettings.quotability, authenticationBox: authBox)
                publishUpdate(.post(GenericMastodonPost.fromStatus(updated, authenticatedDomain: authBox.domain)))
            } catch {
                navigator.didReceiveError(error)
            }
        }
    }
    
    func plainText(from html: String) -> String {
        if let blocks = try? getParseBlocks(from: html) {
            let plain = blocks.reduce(into: "") { partialResult, block in
                if let quote = block as? MastoParseBlockquote {
                    partialResult.append(partialResult.isEmpty ? "\"" : "\n\"")
                    for (idx, row) in quote.contents.enumerated() {
                        if idx > 0 {
                            partialResult.append("\n")
                        }
                        for inlineElement in row.contents {
                            switch inlineElement.type {
                            case .text:
                                partialResult.append(inlineElement.contents)
                            case .code:
                                partialResult.append("\'\(inlineElement.contents)\'")
                            }
                        }
                    }
                    partialResult.append("\"")
                } else if let row = block as? MastoParseContentRow {
                    if !partialResult.isEmpty {
                        partialResult.append("\n")
                    }
                    for inlineElement in row.contents {
                        switch inlineElement.type {
                        case .text:
                            partialResult.append(inlineElement.contents)
                        case .code:
                            partialResult.append("`\(inlineElement.contents)`")
                        }
                    }
                }
            }
            return plain
        } else {
            return ""
        }
    }
    
    func doRemoveQuote(from quotingPost: MastodonContentPost, askFirst: Bool, navigator: MastodonNavigationRouter) async throws {
        if askFirst {
            navigator.activeAlert = .confirmRemoveQuote(username: quotingPost.initialDisplayInfo().actionableAuthorDisplayName, didConfirm: { confirmed in
                guard confirmed else { return }
                Task {
                    await self.commitRemoveQuote(from: quotingPost, navigator: navigator)
                }
            })
        } else {
            await commitRemoveQuote(from: quotingPost, navigator: navigator)
        }
    }
    
    func doAction(_ action: MastodonPostMenuAction, forAccount account: MastodonAccount, relationshipViewModel: RelationshipViewModel, navigator: MastodonNavigationRouter) async throws {
        switch action {
        case .follow:
            try await relationshipViewModel.doMenuAction(.follow, forAccount: account, navigator: navigator)
        case .unfollow:
            try await relationshipViewModel.doMenuAction(.unfollow, forAccount: account, navigator: navigator)
        case .mute:
            try await relationshipViewModel.doMenuAction(.mute, forAccount: account, navigator: navigator)
        case .unmute:
            try await relationshipViewModel.doMenuAction(.unmute, forAccount: account, navigator: navigator)
        case .blockUser:
            try await relationshipViewModel.doMenuAction(.blockUser, forAccount: account, navigator: navigator)
        case .unblockUser:
            try await relationshipViewModel.doMenuAction(.unblockUser, forAccount: account, navigator: navigator)
        default:
            throw PostActionFailure.unsupportedAction
        }
    }
    
    func canTranslate(post: MastodonContentPost) -> Bool {
        guard let postLanguage = post.content.language else { return false }
        guard let deviceLanguage = Bundle.main.preferredLocalizations.first else { return false }
        guard deviceLanguage != postLanguage else { return false }
        
        
        return authenticatedUser?.authentication.instanceConfiguration?.canTranslateFrom(
            postLanguage,
            to: deviceLanguage
        ) ?? false
    }
    
    func translation(forContentPostId postId: MastodonSDK.Mastodon.Entity.Status.ID) -> MastodonSDK.Mastodon.Entity.Translation? {
        return translations[postId]
    }
    
    private func refetchAndDisplay(actionablePostID: Mastodon.Entity.Status.ID) {
        Task { [weak self] in
            guard let authBox = self?.authenticatedUser else { return }
            let status = try await APIService.shared.status(statusID: actionablePostID, authenticationBox: authBox).value
            let updated = GenericMastodonPost.fromStatus(status, authenticatedDomain: authBox.domain)
            FeedCoordinator.shared.publishUpdate(.post(updated))
        }
    }
    
    // TRANSLATION
    private func getTranslation(forPost post: MastodonContentPost) async throws {
        guard translations[post.id] == nil else { return }
        
        guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
        
        let translation = try await APIService.shared
            .translateStatus(
                statusID: post.id,
                authenticationBox: authenticatedUser
            ).value
        
        guard let translationContent = translation.content, translationContent.isNotEmpty else { throw PostActionFailure.translationEmptyOrInvalid }
        
        translations[post.id] = translation
    }
    
    // BOOST with optional confirmation dialog
    func boost(_ actionablePostId: Mastodon.Entity.Status.ID, askFirst: Bool, navigator: MastodonNavigationRouter) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            
            if askFirst {
                navigator.activeAlert = .confirmBoostOfPost(didConfirm: { [weak self] confirmed in
                    guard confirmed else { return }
                    Task {
                        await self?.boost(actionablePostId, askFirst: false, navigator: navigator)
                    }
                })
            } else {
                let updated = try await APIService.shared.boost(boostableStatusId: actionablePostId, authenticationBox: authenticatedUser) // this returns a new post, which is the boost action
                let updatedActionable = updated.reblog ?? updated // when updating the existing records, we only care about the original post
                FeedCoordinator.shared.publishUpdate(.post(GenericMastodonPost.fromStatus(updatedActionable, authenticatedDomain: authenticatedUser.domain)))
                clearPendingActions(navigator)
            }
        } catch {
            navigator.didReceiveError(error)
            clearPendingActions(navigator)
        }
    }
    
    // DEFENSIVE ACTIONS
    
    func commitRemoveQuote(from quotingPost: MastodonContentPost, navigator: MastodonNavigationRouter) async {
        do {
            guard let actionablePost = quotingPost.actionablePost as? MastodonBasicPost, let quoted = actionablePost.quotedPost, let quotedId = quoted.fullPost?.id, let authenticatedUser else { throw PostActionFailure.noActionablePostId }
            let updated = try await APIService.shared.revokeQuoteAuthorization(forQuotedId: quotedId, fromQuotingId: actionablePost.id, authenticationBox: authenticatedUser)
            FeedCoordinator.shared.publishUpdate(.post(GenericMastodonPost.fromStatus(updated, authenticatedDomain: authenticatedUser.domain)))
            clearPendingActions(navigator)
        } catch {
            navigator.didReceiveError(error)
            clearPendingActions(navigator)
        }
    }
    
    func deletePost(_ postID: Mastodon.Entity.Status.ID, askFirst: Bool, navigator: MastodonNavigationRouter) async {
        do {
            if askFirst {
                navigator.activeAlert = .confirmDeleteOfPost(didConfirm: { [weak self] confirmed in
                    guard confirmed else { return }
                    Task {
                        await self?.deletePost(postID, askFirst: false, navigator: navigator)
                    }
                })
            } else {
                guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
                let deletedStatus = try await APIService.shared.deleteContentPost(postID, authenticationBox: authenticatedUser)
                FeedCoordinator.shared.publishUpdate(.deletedPost(deletedStatus.id))
                self.clearPendingActions(navigator)
            }
        } catch {
            self.clearPendingActions(navigator)
            navigator.didReceiveError(error)
        }
    }
}

extension TimelineListViewModel {
    struct FamiliarAccountsSummary {
        let firstFew: [MastodonAccount]
        let totalCount: Int
    }
    
    func familiarAccounts(maxCount: Int) -> FamiliarAccountsSummary? {
        let firstFew = feedLoader?.records.allRecords.compactMap { item in
            switch item {
            case .account(let accountRowViewModel):
                accountRowViewModel.account
            default:
                nil
            }
        }.prefix(maxCount)
        guard let firstFew, !firstFew.isEmpty else {
            return nil
        }
        return FamiliarAccountsSummary(firstFew: Array(firstFew), totalCount: feedLoader?.records.allRecords.count ?? 0)
    }
}
