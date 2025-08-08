// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import Combine
import MastodonUI
import Meta

private func debugScroll(_ message: String) {
#if DEBUG && false
    print("SCROLL: \(message)")
#endif
}

class HomeTimelineListViewController: UIHostingController<HomeTimelineListView>
{
    private let viewModel = HomeTimelineListViewModel(timeline: .following)
    private var navigationFlow: NavigationFlow?
    private let _mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private var scrollToTopUpdateSubscription: AnyCancellable?
    
    init() {
        let root = HomeTimelineListView(viewModel: viewModel)
        super.init(rootView: root)
        viewModel.parentVcPresentScene = { (scene, transition) in
            self.sceneCoordinator?.present(scene: scene, transition: transition)
        }
        viewModel.presentDonationDialog = { [weak self] campaign in
            guard let self else { return }
            guard let coordinator = self.sceneCoordinator, let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
            self.navigationFlow = NewDonationNavigationFlow(flowPresenter: self, campaign: campaign, authenticationBox: authBox, sceneCoordinator: coordinator)
            self.navigationFlow?.presentFlow { [weak self] in
                self?.navigationFlow = nil
            }
        }
        viewModel.hostingViewController = self
        
        setUpTimelineSelectorButton()
        setUpScrollToTop()
        showSettingsButton(true)
    }
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let setting = SettingService.shared.currentSetting.value else { return }
        
        _ = self.sceneCoordinator?.present(scene: .settings(setting: setting), from: self, transition: .none)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError(
            "init(coder:) not implemented for HomeTimelineListViewController")
    }
    
    lazy var settingBarButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.tintColor = Asset.Colors.Brand.blurple.color
        barButtonItem.image = UIImage(systemName: "gear")
        barButtonItem.accessibilityLabel = L10n.Common.Controls.Actions.settings
        barButtonItem.target = self
        barButtonItem.action = #selector(Self.settingBarButtonItemPressed(_:))
        return barButtonItem
    }()
    
    func setUpTimelineSelectorButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: timelineSelectorButton)
    }
    
    var scrollToTopButton: UIButton?
    
    func setUpScrollToTop() {
        let button = UIButton(configuration: .plain())
        button.addTarget(self, action: #selector(scrollToTop), for: .touchUpInside)
        self.scrollToTopButton = button
        self.navigationItem.titleView = button
        scrollToTopUpdateSubscription = viewModel.$unreadCount.sink { [weak self] unread in
            self?.updateScrollToTopButton(unread)
        }
    }
    
    func updateScrollToTopButton(_ waitingCount: Int) {
        if waitingCount > 0 {
            scrollToTopButton?.isHidden = false
            scrollToTopButton?.configuration?.title = "\(waitingCount)+ Unread ^"
            scrollToTopButton?.configuration?.baseForegroundColor = Asset.Colors.accent.color
        } else {
            scrollToTopButton?.isHidden = true
        }
    }
    
    @objc func scrollToTop() {
        viewModel.scrollToTop()
    }
    
    func showSettingsButton(_ show: Bool) {
        if show {
            self.navigationItem.rightBarButtonItem = settingBarButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    lazy var timelineSelectorButton = {
        let button = UIButton(type: .custom)
        
        button.setAttributedTitle(
            .init(string: L10n.Scene.HomeTimeline.TimelineMenu.following, attributes: [
                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
            ]),
            for: .normal)
        
        let imageConfiguration = UIImage.SymbolConfiguration(paletteColors: [.secondaryLabel, .secondarySystemFill])
            .applying(UIImage.SymbolConfiguration(textStyle: .subheadline))
            .applying(UIImage.SymbolConfiguration(pointSize: 16, weight: .bold, scale: .medium))
        
        button.configuration = {
            var config = UIButton.Configuration.plain()
            config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            config.imagePadding = 8
            config.image = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: imageConfiguration)
            config.imagePlacement = .trailing
            return config
        }()
        
        button.showsMenuAsPrimaryAction = true
        button.menu = generateTimelineSelectorMenu()
        return button
    }()
    
    private func generateTimelineSelectorMenu() -> UIMenu {
        let showFollowingAction = UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.following, image: .init(systemName: "house")) { [weak self] _ in
            guard let self else { return }
            
            viewModel.timeline = .following
            self.timelineSelectorButton.setAttributedTitle(
                .init(string: L10n.Scene.HomeTimeline.TimelineMenu.following, attributes: [
                    .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                ]),
                for: .normal)
            
            self.timelineSelectorButton.sizeToFit()
            self.timelineSelectorButton.menu = self.generateTimelineSelectorMenu()
        }
        
        let showLocalTimelineAction = UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.localCommunity, image: .init(systemName: "building.2")) { [weak self] action in
            guard let self else { return }
            
            viewModel.timeline = .local
            timelineSelectorButton.setAttributedTitle(
                .init(string: L10n.Scene.HomeTimeline.TimelineMenu.localCommunity, attributes: [
                    .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                ]),
                for: .normal)
            timelineSelectorButton.sizeToFit()
            timelineSelectorButton.menu = generateTimelineSelectorMenu()
        }
        
        switch viewModel.timeline {
        case .following:
            showLocalTimelineAction.state = .off
            showFollowingAction.state = .on
        case .local:
            showLocalTimelineAction.state = .on
            showFollowingAction.state = .off
        case .list:
            showLocalTimelineAction.state = .off
            showFollowingAction.state = .off
        case .hashtag:
            showLocalTimelineAction.state = .off
            showFollowingAction.state = .off
        }
        
        let listsSubmenu = UIDeferredMenuElement.uncached { [weak self] callback in
            guard let self else { return callback([]) }
            
            Task { @MainActor in
                guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
                
                let lists = (try? await Mastodon.API.Lists.getLists(
                    session: .shared,
                    domain: currentUser.domain,
                    authorization: currentUser.userAuthorization
                ).singleOutput().value) ?? []
                
                var listEntries = lists.map { entry in
                    return LabeledAction(title: entry.title, image: nil, handler: { [weak self] in
                        guard let self else { return }
                        viewModel.timeline = .list(entry.id)
                        timelineSelectorButton.setAttributedTitle(
                            .init(string: entry.title, attributes: [
                                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                            ]),
                            for: .normal)
                        timelineSelectorButton.sizeToFit()
                        timelineSelectorButton.menu = generateTimelineSelectorMenu()
                    }).menuElement
                }
                
                if listEntries.isEmpty {
                    listEntries = [
                        UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.Lists.emptyMessage, attributes: [.disabled], handler: {_ in })
                    ]
                }
                
                callback(listEntries)
            }
        }
        
        let listsMenu = UIMenu(
            title: L10n.Scene.HomeTimeline.TimelineMenu.Lists.title,
            image: UIImage(systemName: "list.bullet.rectangle.portrait"),
            children: [listsSubmenu]
        )
        
        let hashtagsSubmenu = UIDeferredMenuElement.uncached { [weak self] callback in
            guard let self else { return callback([]) }
            
            Task { @MainActor in
                guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
                
                let lists = (try? await Mastodon.API.Account.followedTags(
                    session: .shared,
                    domain: currentUser.domain,
                    query: .init(limit: nil),
                    authorization: currentUser.userAuthorization
                ).singleOutput().value) ?? []
                
                var listEntries = lists.map { entry in
                    let entryName = "#\(entry.name)"
                    return LabeledAction(title: entryName, image: nil, handler: { [weak self] in
                        guard let self else { return }
                        viewModel.timeline = .hashtag(entry.name)
                        timelineSelectorButton.setAttributedTitle(
                            .init(string: entryName, attributes: [
                                .font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
                            ]),
                            for: .normal)
                        timelineSelectorButton.sizeToFit()
                        timelineSelectorButton.menu = generateTimelineSelectorMenu()
                    }).menuElement
                }
                
                if listEntries.isEmpty {
                    listEntries = [
                        UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.Hashtags.emptyMessage, attributes: [.disabled], handler: {_ in })
                    ]
                }
                
                callback(listEntries)
            }
        }
        
        let hashtagsMenu = UIMenu(
            title: L10n.Scene.HomeTimeline.TimelineMenu.Hashtags.title,
            image: UIImage(systemName: "number"),
            children: [hashtagsSubmenu]
        )
        
        let listsDivider = UIMenu(title: "", options: .displayInline, children: [listsMenu, hashtagsMenu])
        
        return UIMenu(children: [showFollowingAction, showLocalTimelineAction, listsDivider])
    }
}

extension HomeTimelineListViewController: MediaPreviewableViewController {
    var mediaPreviewTransitionController: MediaPreviewTransitionController {
        return _mediaPreviewTransitionController
    }
}

extension MastodonPostMenuAction {
    enum AlertType {
        case noAlert
        case confirmBoostOfPost(didConfirm: ()->())
        case confirmDeleteOfPost(didConfirm: ()->())
        case confirmUnfollow(username: String, didConfirm: ()->())
        case confirmMute(username: String, didConfirm: ()->())
        case confirmUnmute(username: String, didConfirm: ()->())
        case confirmBlock(username: String, didConfirm: ()->())
        case confirmUnblock(username: String, didConfirm: ()->())
        
        var title: String {
            switch self {
            case .noAlert:
                ""
                
            case .confirmBoostOfPost:
                L10n.Common.Alerts.BoostAPost.titleBoost
                
            case .confirmDeleteOfPost:
                L10n.Common.Alerts.DeletePost.title
                
            case .confirmUnfollow(let username, _):
                L10n.Common.Alerts.UnfollowUser.title("\(username)")
                
            case .confirmMute:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.title
            case .confirmUnmute:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.title
                
            case .confirmBlock:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.title
            case .confirmUnblock:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.title
            }
        }
        
        var messageText: String? {
            switch self {
            case .noAlert, .confirmUnfollow, .confirmBoostOfPost:
                nil
                
            case .confirmMute(let username, _):
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmMuteUser.message(username)
            case .confirmUnmute(let username, _):
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnmuteUser.message(username)
                
            case .confirmBlock(let username, _):
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.message(username)
            case .confirmUnblock(let username, _):
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.message(username)
                
            case .confirmDeleteOfPost:
                L10n.Common.Alerts.DeletePost.message
            }
        }
        
        var shouldBePresented: Bool {
            switch self {
            case .noAlert:
                return false
            default:
                return true
            }
        }
    }
}

enum MastodonTimelineOverlayView {
    case images(focusedImage: Mastodon.Entity.Attachment.ID, ImageGalleryViewModel)
    case altText(String)
}

@MainActor
private class HomeTimelineListViewModel: ObservableObject {
    public var parentVcPresentScene: ((SceneCoordinator.Scene, SceneCoordinator.Transition) -> ())?
    public var presentDonationDialog: ((Mastodon.Entity.DonationCampaign) -> ())?
    private var authenticatedUser: MastodonAuthenticationBox?
    private var instanceConfiguration: MastodonAuthentication.InstanceConfiguration?
    var hostingViewController: MediaPreviewableViewController?
    
    var activeAlert: MastodonPostMenuAction.AlertType = .noAlert {
        didSet {
            if !isPresentingAlert && activeAlert.shouldBePresented {
                isPresentingAlert = true
            }
        }
    }
    var activeOverlay: MastodonTimelineOverlayView? = nil {
        didSet {
            if !isShowingOverlay && activeOverlay != nil {
                isShowingOverlay = true
            } else if isShowingOverlay && activeOverlay == nil {
                isShowingOverlay = false
            }
        }
    }
    
    @Published var isShowingOverlay: Bool = false
    @Published var isPresentingAlert: Bool = false
    @Published var presentedDonationCampaign: Mastodon.Entity.DonationCampaign?
    
    @Published var isPerformingPostAction: (action: MastodonPostMenuAction, post: MastodonContentPost)? = nil
    @Published var isPerformingAccountAction: (action: MastodonPostMenuAction, account: MastodonAccount)? = nil
    
    @Published var feedIsEmpty: Bool = false
    public var hasPresentedFollowSuggestions: Bool = false
    public var iFollowNoOne: Bool {
        if let authBox = authenticatedUser,
           let me = authBox.cachedAccount {
            return me.followingCount == 0
        } else {
            return true
        }
    }

    @Published var currentDisplaySlice = ArraySlice<TimelineItem>()
    private var fullFeed = MastodonFeedLoaderResult(allRecords: [TimelineItem](), canLoadOlder: false)
    private let displaySliceLength = 100
    
    @Published var unreadCount: Int = 0
    @Published var scrollToTopRequested: Bool = false
    
    private var followersAndBlockedChangeSubscription: AnyCancellable?
    private var feedLoader: TimelineFeedLoader?
    private var feedLoaderResultsSubscription: AnyCancellable?
    private var feedLoaderErrorSubscription: AnyCancellable?
    
    var scrollManager: ScrollManager?
    
    private var tailItemIds = [String]()
    private let displayPrepBatchSize = 10
    private var currentlyPreparingForDisplay: [Mastodon.Entity.Status.ID]?
    private var displayPrepRequested: [MastodonPostViewModel]? // only keep the latest batch requested, to avoid getting bogged down while fast scrolling
    
    public var lastReadState: LastReadState = .unknown {
        didSet {
            switch lastReadState {
            case .fromCache, .unknown, .hasScrolled:
                break
            case .interactedWith(let id), .leftWhileViewing(let id), .requestedReload(let id):
                feedLoader?.saveLastRead(id)
            }
        }
    }
    
    // Translations
    private var translations = [ Mastodon.Entity.Status.ID : Mastodon.Entity.Translation]()
    
    func clearPendingActions() {
        if isPerformingPostAction != nil {
            isPerformingPostAction = nil
        }
        if isPerformingAccountAction != nil {
            isPerformingAccountAction = nil
        }
    }
    
    func commitToCache() {
        Task {
            await feedLoader?.commitToCache()
        }
    }
    
    public var timeline: MastodonTimelineType {
        didSet {
            guard feedLoader?.timeline != timeline else { return }
            feedLoader = nil
            lastReadState = .unknown
            currentDisplaySlice = ArraySlice([.loadingIndicator])
            fullFeed = MastodonFeedLoaderResult(allRecords: [], canLoadOlder: true)
            Task {
                try await doInitialLoad()
            }
        }
    }
    
    init(timeline: MastodonTimelineType) {
        self.timeline = timeline
        Task {
            try await doInitialLoad()
        }
    }
    
    private func getDisplaySlice(from items: [TimelineItem], startItemID: Mastodon.Entity.Status.ID?, canLoadOlder: Bool) -> ArraySlice<TimelineItem> {
        let startIndex = items.firstIndex(where: { $0.id == startItemID}) ?? 0
        let endIndex = min(startIndex + displaySliceLength, items.endIndex)
        return items[startIndex..<endIndex] + (endIndex != items.endIndex || canLoadOlder ? [.loadingIndicator] : [])
    }
    
    private func getDisplaySlice(from items: [TimelineItem], midIndex: Int, canLoadOlder: Bool) -> ArraySlice<TimelineItem> {
        let startIndex = max(0, midIndex - (self.displaySliceLength / 2))
        let endIndex = min(startIndex + self.displaySliceLength, items.endIndex)
        return items[startIndex..<endIndex] + (endIndex < items.endIndex || canLoadOlder ? [.loadingIndicator] : [])
    }
    
    func doInitialLoad() async throws {
        guard feedLoader == nil else { return }
        guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { assertionFailure("no active authenticated user, cannot create feed loader"); return }
        clearPendingActions()
        authenticatedUser = currentUser
        instanceConfiguration = currentUser.authentication.instanceConfiguration
        feedLoader = TimelineFeedLoader(currentUser: currentUser, timeline: timeline)
        feedLoaderResultsSubscription = feedLoader?.$records
            .sink{ [weak self] results in
                
                guard results.allRecords.count > 0 || results.canLoadOlder else {
                    self?.feedIsEmpty = true
                    return
                }
                
                if self?.feedIsEmpty == true {
                    self?.feedIsEmpty = false
                }
                
                switch self?.lastReadState {
                case .unknown:
                    if self?.feedLoader?.timeline == .following {
                        if let lastReadMarker = self?.feedLoader?.lastReadMarker {
                            self?.lastReadState = .fromCache(lastReadMarker.lastReadID)
                        }
                    }
                default:
                    break
                }
                
                let needsPrep: [MastodonPostViewModel] = results.allRecords.compactMap { item in
                    switch item {
                    case .loadingIndicator, .missingPosts:
                        return nil
                    case .post(let viewModel):
                        switch viewModel.displayPrepStatus {
                        case .unprepared:
                            return viewModel
                        case .donePreparing:
                            return nil
                        }
                    }
                }
                self?.doPrepareForDisplay(needsPrep, contentWidth: 0, completion: {
                    DispatchQueue.main.async {
                        guard let self else { return }
                        
                        let newDisplaySlice: ArraySlice<TimelineItem>?
                        switch self.lastReadState {
                        case .unknown, .hasScrolled, .interactedWith, .leftWhileViewing:
                            if let firstCurrentID = self.fullFeed.allRecords.first(where: {
                                switch $0 {
                                case .post: return true
                                default: return false
                                }
                            })?.id {
                                // better to leave things alone in these cases rather than risk jumping the scroll unexpectedly
                                newDisplaySlice = nil
                            } else {
                                // current timeline is empty, so take a slice of these items to display
                                newDisplaySlice = self.getDisplaySlice(from: results.allRecords, startItemID: nil, canLoadOlder: results.canLoadOlder)
                            }
                        case .fromCache(let id):
                            newDisplaySlice = self.getDisplaySlice(from: results.allRecords, startItemID: id, canLoadOlder: results.canLoadOlder) // put the cached last read item at the top of the display
                        case .requestedReload(let anchorID):
                            let anchorItemIndex = results.allRecords.firstIndex(where: {
                                switch $0 {
                                case .post(let postViewModel): return postViewModel.initialDisplayInfo.id == anchorID
                                default: return false
                                }
                            }) ?? 0
                            
                            newDisplaySlice = self.getDisplaySlice(from: results.allRecords, midIndex: anchorItemIndex, canLoadOlder: results.canLoadOlder)
                        }

                        if let newDisplaySlice {
                            self.tailItemIds = newDisplaySlice.suffix(5).map { $0.id }
                            self.fullFeed = results
                            self.currentDisplaySlice = newDisplaySlice
                        }
                    }
                })
            }
        // TODO: add feedLoaderErrorSubscription
        feedLoader?.doFirstLoad()
        
        followersAndBlockedChangeSubscription = AuthenticationServiceProvider.shared.$didChangeFollowersAndFollowing.sink {
            [weak self] userID in
            guard userID == self?.authenticatedUser?.globallyUniqueUserIdentifier else { return }
            self?.feedLoader?.requestLoad(.reload)
        }
    }
    
    func forceLastReadToTop(_ lastRead: Mastodon.Entity.Status.ID) {
        let newDisplaySlice = getDisplaySlice(from: fullFeed.allRecords, startItemID: lastRead, canLoadOlder: fullFeed.canLoadOlder)
        currentDisplaySlice = newDisplaySlice
    }
    
    func requestLoad(_ loadRequest: MastodonFeedLoaderRequest) {
        if loadRequest == .older && currentDisplaySlice.endIndex < fullFeed.allRecords.endIndex {
            currentDisplaySlice = getDisplaySlice(from: fullFeed.allRecords, midIndex: currentDisplaySlice.endIndex, canLoadOlder: fullFeed.canLoadOlder)
        } else {
            guard let feedLoader else { assertionFailure(); return }
            feedLoader.requestLoad(loadRequest)
        }
    }
    
    func refreshFeedFromTop() async {
        if currentDisplaySlice.startIndex > 0 {
            currentDisplaySlice = getDisplaySlice(from: fullFeed.allRecords, midIndex: currentDisplaySlice.startIndex, canLoadOlder: fullFeed.canLoadOlder)
        } else {
            guard let feedLoader else { assertionFailure(); return }
            if feedLoader.permissionToLoadImmediately {
                await feedLoader.loadImmediately(.reload)
                await feedLoader.clearCache() // reset the cache when user refreshes
                commitToCache()
            }
        }
    }
    
    func scrollToTop() {
        let topItem = fullFeed.allRecords.first
        switch topItem {
        case nil, .loadingIndicator, .missingPosts:
            lastReadState = .unknown
        case .post(let viewModel):
            lastReadState = .requestedReload(viewModel.initialDisplayInfo.id)
        }
        currentDisplaySlice = getDisplaySlice(from: fullFeed.allRecords, startItemID: nil, canLoadOlder: fullFeed.canLoadOlder)
        scrollToTopRequested = true
    }
    
    func didAppear(_ postViewModel: MastodonPostViewModel, contentWidth: CGFloat) {
        guard currentDisplaySlice.endIndex < fullFeed.allRecords.endIndex || fullFeed.canLoadOlder == true else {
            debugScroll("have loaded as far back as possible")
            return
        }
        
        if let lastRead = lastReadState.id {
            if postViewModel.initialDisplayInfo.id == lastRead {
                lastReadRecentlyDisappeared = false
            } else if lastReadRecentlyDisappeared {
                lastReadRecentlyDisappeared = false
                debugScroll("last read has scrolled because the last read disappeared and then something else appeared")
                lastReadState = .hasScrolled(from: lastRead)
            }
        } else {
            lastReadRecentlyDisappeared = false
        }
        
        if tailItemIds.contains(postViewModel.initialDisplayInfo.id) {
            tailItemIds = []
            lastReadState = .requestedReload(postViewModel.initialDisplayInfo.id)
            if currentDisplaySlice.endIndex < fullFeed.allRecords.endIndex {
                currentDisplaySlice = getDisplaySlice(from: fullFeed.allRecords, midIndex: currentDisplaySlice.endIndex, canLoadOlder: fullFeed.canLoadOlder)
            } else {
                requestLoad(.older)
            }
        }
        
        if let scrollManager {
            unreadCount = scrollManager.topVisibleIndex(in: currentDisplaySlice)
        }
    }

    private var lastReadRecentlyDisappeared: Bool = false
    func didDisappear(_ postViewModel: MastodonPostViewModel) {
        if let lastRead = lastReadState.id {
            if postViewModel.initialDisplayInfo.id == lastRead {
                lastReadRecentlyDisappeared = true
            }
        }
    }
    
    func wholeViewDidDisappear() {
        lastReadRecentlyDisappeared = false
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
    
    func suggestAccountsToFollow() {
        guard let authenticatedUser else { return }
        let suggestionAccountViewModel = SuggestionAccountViewModel(authenticationBox: authenticatedUser)
        presentScene(.suggestionAccount(viewModel: suggestionAccountViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
    }
}

extension HomeTimelineListViewModel {
    private func createPrepBatch(anchoredAt anchorIndex: Int) -> [MastodonPostViewModel]? {
        guard let feedLoaderRecords = feedLoader?.records.allRecords else { return nil }
        let batchStart = max(0, anchorIndex - displayPrepBatchSize / 2)
        guard batchStart < feedLoaderRecords.count else { return nil }
        let batchItems = feedLoaderRecords[batchStart...].prefix(displayPrepBatchSize).compactMap { item -> MastodonPostViewModel? in
            switch item {
            case .loadingIndicator, .missingPosts:
                return nil
            case .post(let postViewModel):
                // not donePreparing, not included in currently preparing (inclusion in requested does not matter, because this batch may replace the current requested batch)
                guard postViewModel.displayPrepStatus == .unprepared && currentlyPreparingForDisplay?.contains(postViewModel.initialDisplayInfo.id) != true else { return nil }
                return postViewModel
            }
        }
        
        guard !batchItems.isEmpty else { return nil }
        return batchItems
    }
    
    private func doPrepareForDisplay(_ batch: [MastodonPostViewModel], contentWidth: CGFloat, completion: (()->())? = nil) {
        guard let feedLoader else { return }
        guard currentlyPreparingForDisplay == nil else { /*assertionFailure();*/ return }
        currentlyPreparingForDisplay = batch.map { $0.initialDisplayInfo.id }
        
        Task {
            // make sure we have the full posts to work with (if we are working from a cached timeline)
            let needsCacheFetch = batch.compactMap { postModel in
                return postModel.fullPost == nil ? postModel.initialDisplayInfo.id : nil
            }
            let cachedPosts = await feedLoader.fetchCachedPosts(needsCacheFetch)
            
            var needsRelationshipFetch = [GenericMastodonPost]()
            var needsHtmlProcessing = [MastodonPostViewModel]()
            for postModel in batch {
                if let cachedPost = cachedPosts[postModel.initialDisplayInfo.id] {
                    postModel.fullPost = cachedPost
                }
                
                if let fullPost = postModel.fullPost {
                    switch postModel.myRelationshipToAuthor {
                    case .none:
                        fallthrough
                    case .isNotMe(nil):
                        needsRelationshipFetch.append(fullPost)
                    default:
                        break
                    }
                    
                    if let actionablePost = fullPost.actionablePost, postModel.isShowingTranslation == nil {
                        postModel.isShowingTranslation = canTranslate(post: actionablePost) ? false : nil
                    }
                }
                
                if !postModel.hasCalculatedForWidth(contentWidth) {
                    needsHtmlProcessing.append(postModel)
                }
            }

            let relationshipFetches = needsRelationshipFetch
            async let fetchedRelationships = try await feedLoader.fetchRelationships(relationshipFetches)
            async let htmlProcessingTask = Task {
            }
            
            let _ = await(htmlProcessingTask)
            for postModel in batch {
                postModel.myRelationshipToAuthor = try await fetchedRelationships.first(where: {
                    $0.info?.id == postModel.initialDisplayInfo.actionableAuthorId
                }) ?? feedLoader.myRelationship(to: postModel.initialDisplayInfo.actionableAuthorId)
                if postModel.actionHandler == nil {
                    postModel.actionHandler = self
                }
                postModel.displayPrepStatus = .donePreparing
            }
            
            currentlyPreparingForDisplay = nil
            
            completion?()
        }
    }
}

extension HomeTimelineListViewModel {
    enum LastReadState {
        case unknown
        case hasScrolled(from: Mastodon.Entity.Status.ID)
        case fromCache(Mastodon.Entity.Status.ID)
        case requestedReload(Mastodon.Entity.Status.ID)
        case interactedWith(Mastodon.Entity.Status.ID)
        case leftWhileViewing(Mastodon.Entity.Status.ID)
        
        var id: String? {
            switch self {
            case .fromCache(let id), .requestedReload(let id), .interactedWith(let id), .leftWhileViewing(let id):
                return id
            case .unknown, .hasScrolled:
                return nil
            }
        }
    }
}

extension HomeTimelineListViewModel {
    func askForDonationIfPossible() async {
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

private let scrollViewCoordinateSpace = "ScrollViewCoordinateSpace"

struct HomeTimelineListView: View {
    @ObservedObject private var viewModel: HomeTimelineListViewModel
    @State private var scrollManager = ScrollManager()
    
    @ScaledMetric private var avatarSize = AvatarSize.large
    
    fileprivate init(viewModel: HomeTimelineListViewModel) {
        self.viewModel = viewModel
        viewModel.scrollManager = scrollManager
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) { // to show ALT text when needed, and donation banner
                if viewModel.feedIsEmpty {
                    Image(uiImage: Asset.Asset.friends.image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onAppear() {
                            if viewModel.iFollowNoOne == true, viewModel.hasPresentedFollowSuggestions == false {
                                viewModel.suggestAccountsToFollow()
                                viewModel.hasPresentedFollowSuggestions = true
                            }
                        }
                    Button {
                        viewModel.suggestAccountsToFollow()
                    } label: {
                        Text(L10n.Common.Controls.Actions.findPeople)
                        .bold()
                        .foregroundStyle(.white)
                        .padding()
                        .background(Asset.Colors.accent.swiftUIColor)
                        .cornerRadius(CornerRadius.standard)
                    }
                    .padding(EdgeInsets(top: doublePadding, leading: 0, bottom: doublePadding, trailing: 0))
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack {
                                ForEach(viewModel.currentDisplaySlice, id: \.self) { item in
                                    switch item {
                                    case let .missingPosts(newerThan, olderThan):
                                        GapLoaderView(newerThan: newerThan, olderThan: olderThan, gapDescription: "",
                                                      loadFromTop: {
                                            viewModel.requestLoad(.olderThan(olderThan))
                                        }, loadFromBottom: {
                                            viewModel.requestLoad(.newerThan(newerThan))
                                        })
                                    case .loadingIndicator:
                                        HStack {
                                            Spacer()
                                            ProgressView()
                                                .progressViewStyle(.circular)
                                            Spacer()
                                        }
                                        .padding(EdgeInsets(top: 100, leading: 0, bottom: 100, trailing: 0))
                                        
                                    case .post(let postViewModel):
                                        let usableWidth =
                                        geo.size.width - geo.safeAreaInsets.leading
                                        - geo.safeAreaInsets.trailing
                                        let contentWidth = max(1, usableWidth - (spacingBetweenGutterAndContent) - (doublePadding * 2) - avatarSize)
                                        
                                        VisibilityTrackingView(visibilityDidChange: { isVisible in
                                            if isVisible {
                                                scrollManager.didAppear(postViewModel.initialDisplayInfo.id)
                                                viewModel.didAppear(postViewModel, contentWidth: contentWidth)
                                            } else {
                                                scrollManager.didDisappear(postViewModel.initialDisplayInfo.id)
                                                viewModel.didDisappear(postViewModel)
                                            }
                                        },
                                                               scrollCoordinateSpace: scrollViewCoordinateSpace,
                                                               visibleAreaHeight: geo.size.height)
                                        .frame(width: 10, height: 1)
#if DEBUG
                                        Text(postViewModel.initialDisplayInfo.id)
                                            .foregroundStyle(.red)
                                            .fontWeight(.bold)
#endif
                                        
                                        HomeTimelinePostRowView(contentConcealModel: viewModel.contentConcealModel(forActionablePost: postViewModel.initialDisplayInfo.actionablePostID),
                                                                contentWidth: contentWidth)
                                        .environment(postViewModel)
                                        .padding(EdgeInsets(top: standardPadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                                        .frame(width: usableWidth)
                                        .background(content: {
                                            if postViewModel.initialDisplayInfo.id == viewModel.lastReadState.id {
                                                Rectangle().fill(.yellow)
                                            }
                                        })
                                        
#if DEBUG && false
                                        .background {
                                            if recentlyInsertedItemIds?.contains(postViewModel.initialDisplayInfo.id) == true {
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(.blue.opacity(0.2))
                                            }
                                        }
#endif
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.currentDisplaySlice, initial: true) { oldValue, newValue in
                            if oldValue == newValue {
                                switch viewModel.lastReadState {
                                case .requestedReload:
                                    debugScroll("need to scroll even though nothing has changed")
                                    break  // might need to scroll
                                default:
                                    debugScroll("will not scroll because nothing has changed and last read state is \(viewModel.lastReadState)")
                                    return // try not to mess with things
                                }
                            }
                            switch viewModel.lastReadState {
                            case .unknown, .hasScrolled:
                                debugScroll("NOTHING TO SCROLL TO")
                                break
                            case .fromCache(let id), .requestedReload(let id), .interactedWith(let id), .leftWhileViewing(let id):
                                debugScroll("timelineItems have changed; will try to scroll to \(id)")
                                // keep the last read item scrolled to the top of the view
                                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                                    scrollManager.scrollTo(lastReadID: id, items: newValue, proxy: proxy) { success in
                                        let topVisibleIndex = scrollManager.topVisibleIndex(in: newValue)
                                        viewModel.unreadCount = topVisibleIndex
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.scrollToTopRequested, { oldValue, newValue in
                            if newValue == true, let anchorID = viewModel.currentDisplaySlice.first?.id {
                                scrollManager.scrollTo(lastReadID: anchorID, items: viewModel.currentDisplaySlice, proxy: proxy, completion: { success in
                                    debugScroll("scroll to top completed! \(success)")
                                    DispatchQueue.main.async {
                                        viewModel.scrollToTopRequested = false
                                    }
                                })
                            }
                        })
                        .refreshable {
                            debugScroll("REFRESHABLE?")
                            if let topItem = viewModel.currentDisplaySlice.first?.id {
                                viewModel.lastReadState = .requestedReload(topItem)
                                debugScroll("REFRESHABLE. Scroll lastread is now .requestedReload(\(topItem))")
                            }
                            await viewModel.refreshFeedFromTop()
                        }
                        .accessibilityAction(named: L10n.Common.Controls.Actions.seeMore) {
                            if let topItem = viewModel.currentDisplaySlice.first?.id {
                                viewModel.lastReadState = .requestedReload(topItem)
                            }
                            viewModel.requestLoad(.newer)
                        }
                        .coordinateSpace(name: scrollViewCoordinateSpace)
                    }
                    
                    if let campaign = viewModel.presentedDonationCampaign {
                        DonationPromptBanner(campaign: campaign,
                                             close: {
                            withAnimation {
                                viewModel.presentedDonationCampaign = nil
                            }
                            Mastodon.Entity.DonationCampaign.didDismiss(campaign.id)
                        },
                                             showDonationDialog: {
                            withAnimation {
                                viewModel.presentedDonationCampaign = nil
                            }
                            viewModel.presentDonationDialog?(campaign)
                        })
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .onAppear() {
            viewModel.clearPendingActions()
            scrollManager.viewDidAppear()
            switch viewModel.lastReadState {
            case .unknown, .hasScrolled:
                break
            case .fromCache(let id), .requestedReload(let id), .interactedWith(let id), .leftWhileViewing(let id):
                viewModel.forceLastReadToTop(id)
            }
            Task {
                await viewModel.askForDonationIfPossible()
            }
        }
        .onDisappear() {
            switch viewModel.lastReadState {
            case .unknown, .hasScrolled:
                if let topVisible = viewModel.currentDisplaySlice.first(where: { scrollManager.isVisible($0.id) }) {
                    viewModel.lastReadState = .leftWhileViewing(topVisible.id)
                }
            case .fromCache, .requestedReload, .interactedWith, .leftWhileViewing:
                break
            }
            scrollManager.viewDidDisappear()
            viewModel.wholeViewDidDisappear()
        }
        .alert(viewModel.activeAlert.title, isPresented: $viewModel.isPresentingAlert, presenting: viewModel.activeAlert) { alert in
            alertContents(alert)
        } message: { alert in
            if let messageText = alert.messageText {
                Text(messageText)
            }
        }
        .overlay {
            if viewModel.isShowingOverlay, let activeOverlay = viewModel.activeOverlay {
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {
                        ZStack {
                            Color.black.opacity(0.6)
                                .ignoresSafeArea()
                                .onTapGesture {
                                    viewModel.activeOverlay = nil
                                }
                            
                            activeOverlay.view(sizedForFrame: geo.size)
                        }
                        
                        Button {
                            viewModel.activeOverlay = nil
                        } label: {
                            Image(systemName: "xmark.circle")
                                .font(.title)
                                .foregroundStyle(.white)
                        }
                        .padding(standardPadding)
                    }
                }
            }
        }
    }
    
    @ViewBuilder func alertContents(_ alert: MastodonPostMenuAction.AlertType) -> some View {
        switch alert {
        case .noAlert:
            Text("no alert")
        case .confirmBoostOfPost(let didConfirm):
            cancelButton()
            Button {
                didConfirm()
            } label: {
                Text(L10n.Common.Alerts.BoostAPost.boost)
            }
            
        case .confirmDeleteOfPost(let didConfirm):
            cancelButton()
            Button(role: .destructive) {
                didConfirm()
            } label: {
                Text(L10n.Common.Controls.Actions.delete)
            }
            
        case .confirmUnfollow(_, let didConfirm):
            cancelButton()
            Button(role: .destructive) {
                didConfirm()
            } label: {
                Text(L10n.Common.Alerts.UnfollowUser.unfollow)
            }
            
        case .confirmMute(username: let username, didConfirm: let didConfirm):
            cancelButton()
            Button(role: .destructive) {
                didConfirm()
            } label: {
                Text(L10n.Common.Controls.Friendship.muteUser(username))
            }
        case .confirmUnmute(username: let username, didConfirm: let didConfirm):
            cancelButton()
            Button {
                didConfirm()
            } label: {
                Text(L10n.Common.Controls.Friendship.unmuteUser(username))
            }
            
        case .confirmBlock(username: let username, didConfirm: let didConfirm):
            cancelButton()
            Button(role: .destructive) {
                didConfirm()
            } label: {
                Text(L10n.Common.Controls.Friendship.blockUser(username))
            }
        case .confirmUnblock(username: let username, didConfirm: let didConfirm):
            cancelButton()
            Button {
                didConfirm()
            } label: {
                Text(L10n.Common.Controls.Friendship.unblockUser(username))
            }
        }
    }
    
    @ViewBuilder func cancelButton() -> some View {
        Button(role: .cancel) {
            viewModel.clearPendingActions()
        }
        label: {
            Text(L10n.Common.Controls.Actions.cancel)
        }
    }
}


fileprivate let totalRetryCount: Int = 5
fileprivate class ScrollManager {
    public var isAppeared: Bool = false
    
    private var visibleItems = Set<String>()
    
    func isVisible(_ id: String) -> Bool {
        return visibleItems.contains(id)
    }
    
    func reset() {
        visibleItems.removeAll()
    }
    
    func viewDidAppear() {
        assert(!isAppeared)
        isAppeared = true
        debugScroll("view appeared +")
    }
    
    func viewDidDisappear() {
        assert(isAppeared)
        isAppeared = false
        debugScroll("view DISAPPEARED -")
    }
    
    func didAppear(_ itemID: String) {
        visibleItems.insert(itemID)
        debugScroll("item appeared + \(itemID)")
    }
    
    func didDisappear(_ itemID: String) {
        visibleItems.remove(itemID)
        debugScroll("item disappeared - \(itemID)")
    }

    func scrollTo(lastReadID: String?, items: ArraySlice<TimelineItem>, proxy: ScrollViewProxy, retryCount: Int = totalRetryCount, completion: @escaping (Bool)->()) {
        guard isAppeared else {
            // the proxy scroll does not behave correctly until the view is on screen
            debugScroll("cannot scroll! have not appeared!")
            return
        }
        let lastReadMatch = items.first(where: { lastReadID == $0.id })
        guard let anchorItem = lastReadMatch else {
            // there is nothing to scroll to
            debugScroll("will not scroll because there is no match!")
            return
        }
        DispatchQueue.main.async {
            let firstVisibleItem = items.first(where: { self.visibleItems.contains($0.id) })
            debugScroll("attempting scroll to \(anchorItem.id) with \(retryCount) retries left. top visible item is \(firstVisibleItem?.id ?? "NIL").  All \(self.visibleItems.count) visible items:")
            for itemID in self.visibleItems {
                debugScroll(itemID)
            }
            proxy.scrollTo(anchorItem, anchor: .top)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100 * (totalRetryCount - retryCount))) { [weak self] in
                guard let self, retryCount > 0 else {
                    debugScroll("failed all retries!")
                    completion(false)
                    return
                }
                if let lastReadID, !self.visibleItems.contains(lastReadID) {
                    scrollTo(lastReadID: lastReadID, items: items, proxy: proxy, retryCount: retryCount - 1, completion: completion)
                } else {
                    debugScroll("Success with \(retryCount) tries left!")
                    completion(true)
                }
            }
        }
    }
    
    func topVisibleIndex(in items: ArraySlice<TimelineItem>) -> Int {
        let index = items.firstIndex(where: { visibleItems.contains($0.id) })
        debugScroll("top visible index is \(index ?? 0) (with a list of \(visibleItems.count) visible items)")
        return index ?? 0
    }
}

extension MastodonTimelineOverlayView {
    @ViewBuilder func view(sizedForFrame frameSize: CGSize) -> some View {
        switch self {
        case .altText(let altTextString):
            AltTextView(altTextString: altTextString, frameSize: frameSize)
        case .images(let focusedImage, let viewModel):
            if let img = viewModel.imageAttachments.first(where: { $0.id == focusedImage }) {
                ZoomableBlurhashImageView(image: img, viewModel: viewModel, frameSize: frameSize)
            }
        }
    }
}

private struct HomeTimelinePostRowView: View {

    @Environment(MastodonPostViewModel.self) private var viewModel
    @ObservedObject var contentConcealModel: ContentConcealViewModel
    let contentWidth: CGFloat
    
    let distanceFromAvatarLeadingEdgeToContentLeadingEdge: CGFloat = spacingBetweenGutterAndContent + AvatarSize.large
    
    var body: some View {
        let actionablePost = viewModel.fullPost?.actionablePost
        let author = actionablePost?.metaData.author ?? viewModel.fullPost?.metaData.author
        
        VStack(alignment: .gutterAlign, spacing: tinySpacing) {
            
            viewModel.socialContextHeader
            
            HStack(alignment: .top) {
            
                AvatarView(size: .large, authorAvatarUrl: author?.avatarURL ?? viewModel.initialDisplayInfo.actionableAuthorStaticAvatar, goToProfile: {
                    goToProfile(author)
                })
                
                VStack(spacing: spacingBetweenGutterAndContent) {
                    AuthorHeaderView(timestamper: viewModel.timestamper)
                        .environment(viewModel)
                    
                    contentConcealLozenge
                        .frame(width: contentWidth)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if contentConcealModel.currentMode.isShowingContent, let actionHandler = viewModel.actionHandler {
                        if viewModel.isShowingTranslation == true, let translatablePost = viewModel.fullPost?.actionablePost, let translation = actionHandler.translation(forContentPostId: translatablePost.id) {
                            TranslationInfoView(translationInfo: translation, showOriginal: { actionHandler.doAction(.showOriginalLanguage, forPost: translatablePost) }
                            )
                            .frame(width: contentWidth, alignment: .leading)
                        }
                        viewModel.textContentView()
                            .frame(width: contentWidth, alignment: .leading)
                            .onTapGesture {
                                viewModel.openThreadView()
                            }
                            .environment(\.openURL, OpenURLAction { url in
                                if viewModel.openURL(url) {
                                    return .handled
                                } else {
                                    return .systemAction(url)
                                }
                            })
                        
                        if let attachment = viewModel.fullPost?.actionablePost?.content.attachment {
                            switch attachment {
                            case .media(let array):
                                MediaAttachment(array, altTextTranslations: viewModel.altTextTranslations).view(withContentConcealModel: contentConcealModel, actionHandler: actionHandler)
                                    .frame(width: contentWidth)
                            case .poll(let poll):
                                let emojis = viewModel.fullPost?.actionablePost?.content.htmlWithEntities?.emojis
                                PollView(viewModel: PollViewModel(pollEntity: poll, emojis: emojis, optionTranslations: viewModel.isShowingTranslation == true ? viewModel.pollOptionTranslations : nil, containingPostID: viewModel.initialDisplayInfo.actionablePostID, actionHandler: actionHandler), contentWidth: contentWidth)
                                    .frame(width: contentWidth)
                            case .linkPreviewCard(let card):
                                LinkPreviewCard(cardEntity: card, fittingWidth: contentWidth, navigateToScene: { (scene, transition) in
                                    actionHandler.presentScene(scene, fromPost: viewModel.initialDisplayInfo.id, transition: transition)
                                })
                                .frame(width: contentWidth)
                            }
                        }
                    }
                    
#if DEBUG && false
                    VStack {
                        Text(viewModel.post.id)
                        if let actionableID = viewModel.post.actionablePost?.id, actionableID != viewModel.post.id {
                            Text("(content: \(actionableID))")
                        }
                    }
                    .foregroundStyle(.red)
                    .font(.footnote)
#endif
                    
                    if let actionablePost = viewModel.fullPost?.actionablePost {
                        Spacer()
                            .frame(height: 0)  // gives double spacing between bottom of post content and action bar
                        ActionBar()
                            .environment(viewModel)
                            .frame(width: contentWidth, alignment: .leading)
                    }
                }
            }
        }
        .background(.background.opacity(0.01)) // To allow tap in margin to open threadview. Opacity of 0 does not accept taps, nor does .clear.
        .onTapGesture {
            viewModel.openThreadView()
        }
        .onAppear() {
            //assert(viewModel.fullPost != nil)
        }
    }
    
    @ViewBuilder func componentView(_ component: PostViewComponent) -> some View {
        switch component {
        case .content(let string):
            PostContentView(text: string)
        case .hashtags(let tags):
            HashtagRowView(hashtags: tags)
        }
    }
    
    func goToProfile(_ account: MastodonAccount?) {
        guard let account else { return }
        viewModel.goToProfile(account)
    }
}

extension HomeTimelinePostRowView {
    @ViewBuilder var contentConcealLozenge: some View {
        if let whenHiding = contentConcealModel.buttonText(whenHiding: true), let whenShowing = contentConcealModel.buttonText(whenHiding: false) {
            ShowMoreLozenge(buttonTextWhenHiding: whenHiding, buttonTextWhenShowing: whenShowing, viewModel: ShowMoreViewModel(isShowing: contentConcealModel.currentMode.isShowingContent, isFilter: contentConcealModel.currentModeIsFilter, reasons: contentConcealModel.currentMode.reasons ?? [], showMore: {
                show in
                if show {
                    contentConcealModel.showMore()
                } else {
                    contentConcealModel.hide()
                }
            }))
        }
    }
}

private struct PostContentView: View {
    //    @ObservedObject var contentWarningViewModel
    let text: String
    
    var body: some View {
        Text(text)
    }
}

private struct LinkPreviewView: View {
    let linkPreview: Mastodon.Entity.Card
    
    var body: some View {
        Text("a link preview")
    }
}

private struct HashtagRowView: View {
    let hashtags: [String]
    
    var body: some View {
        Text("#\(hashtags.first) and \(hashtags.count - 1) others")
    }
}

private struct ActionBar: View {
    
    @Environment(MastodonPostViewModel.self) private var viewModel

    var body: some View {
        HStack() {
            if let actionablePost = viewModel.fullPost?.actionablePost {
                actionButton(forPost: actionablePost, action: .reply)
                Spacer()
                actionButton(forPost: actionablePost, action: .boost)
                Spacer()
                actionButton(forPost: actionablePost, action: .favourite)
                Spacer()
                actionButton(forPost: actionablePost, action: .bookmark)
                Spacer()
                ActionBarMenuButton()
                    .environment(viewModel)
                Spacer()
            }
        }
    }
    
    struct ActionBarMenuButton: View {
        @Environment(MastodonPostViewModel.self) private var viewModel
        
        var body: some View {
            Menu {
                if let relationship = viewModel.myRelationshipToAuthor {
                    ForEach(submenus(forRelationshipToAuthor: relationship, isShowingTranslation: viewModel.isShowingTranslation), id: \.self.id) { submenu in
                        ForEach(submenu.items, id: \.self) { menuAction in
                            if let actionablePost = viewModel.fullPost?.actionablePost {
                                Button(role: menuAction.isDestructive ? .destructive : nil) {
                                    
                                    viewModel.actionHandler?.doAction(menuAction, forPost: actionablePost)
                                }
                                label: {
                                    Label(menuAction.labelText(username: actionablePost.metaData.author.displayInfo.displayName, postLanguage: actionablePost.content.language), systemImage: menuAction.iconSystemName)
                                }
                            }
                        }
                        Divider()
                    }
                }
            } label: {
                Label("", systemImage: "ellipsis")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        
        func submenus(forRelationshipToAuthor relationship: MastodonAccount.Relationship, isShowingTranslation: Bool?) -> [MastodonPostMenuAction.Submenu] {
            return MastodonPostMenuAction.menuItems(forPostBy: relationship, isShowingTranslation: isShowingTranslation)
        }
    }
    
    private func overrideState(for postAction: PostAction, of actionablePost: MastodonContentPost) -> AsyncBool? {
        switch (viewModel.isDoingAction, postAction) {
        case (nil, _):
            return nil
        case (.boost, .boost), (.favourite, .favourite), (.bookmark, .bookmark):
            return .settingToTrue
        case (.unboost, .boost), (.unfavourite, .favourite), (.unbookmark, .bookmark):
            return .settingToFalse
        default:
            return nil
        }
    }
    
    private func actionButton(forPost actionablePost: MastodonContentPost, action: PostAction) -> StatefulCountedActionButton {
        let metrics = actionablePost.content.metrics
        let myActions = actionablePost.content.myActions
        let overrideState = overrideState(for: .reply, of: actionablePost)
        switch action {
        case .reply:
            let state = overrideState ?? AsyncBool.fromBool(myActions.boosted)
            return StatefulCountedActionButton(type: .reply, actionState: .init(count: metrics.replyCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.reply, forPost: actionablePost)
                default:
                    break
                }
            })
        case .boost:
            let state = overrideState ?? AsyncBool.fromBool(myActions.boosted)
            return StatefulCountedActionButton(type: .boost, actionState: .init(count: metrics.boostCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.boost, forPost: actionablePost)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unboost, forPost: actionablePost)
                default:
                    break
                }
            })
        case .favourite:
            let state = overrideState ?? AsyncBool.fromBool(myActions.favorited)
            return StatefulCountedActionButton(type: .favourite, actionState: .init(count: metrics.favoriteCount, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.favourite, forPost: actionablePost)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unfavourite, forPost: actionablePost)
                default:
                    break
                }
            })
        case .bookmark:
            let state = overrideState ?? AsyncBool.fromBool(myActions.bookmarked)
            return StatefulCountedActionButton(type: .bookmark, actionState: .init(count: nil, isSelected: state), doAction: {
                switch state {
                case .isFalse:
                    viewModel.actionHandler?.doAction(.bookmark, forPost: actionablePost)
                case .isTrue:
                    viewModel.actionHandler?.doAction(.unbookmark, forPost: actionablePost)
                default:
                    break
                }
            })
        }
     }
}

private enum PostViewComponent {
    case content(String)
    case hashtags([String])
}

struct AttributedStringDisplayInfo {
    let attributedString: AttributedString
    let layoutSizes: [CGSize]
    
    func hasCalculatedForWidth(_ width: CGFloat) -> Bool {
        return layoutSizes.contains(where: { $0.width == floor(width)})
    }
}

@MainActor
@Observable class MastodonPostViewModel {
    
    enum DisplayPrepStatus {
        case unprepared
        case donePreparing
    }
    
    nonisolated let initialDisplayInfo: GenericMastodonPost.InitialDisplayInfo
    
    var fullPost: GenericMastodonPost? = nil
    var myRelationshipToAuthor: MastodonAccount.Relationship? = nil
    var originalContentDisplayInfo: AttributedStringDisplayInfo?
    var translatedContentDisplayInfo: AttributedStringDisplayInfo?

    var displayPrepStatus: DisplayPrepStatus = .unprepared
    var isShowingTranslation: Bool? = nil
    var isDoingAction: MastodonPostMenuAction? = nil
    
    var actionHandler: MastodonPostMenuActionHandler? = nil
    let timestamper: TimestampUpdater = TimestampUpdater.timestamper(withInterval: 30)
    
    private(set) var translation: Mastodon.Entity.Translation? = nil
    
    nonisolated
    init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo) {
        self.initialDisplayInfo = initialDisplay
    }
    
    private init(_ initialDisplay: GenericMastodonPost.InitialDisplayInfo, fullPost: GenericMastodonPost? = nil, isShowingTranslation: Bool? = nil, isDoingAction: MastodonPostMenuAction? = nil, myRelationshipToAuthor: MastodonAccount.Relationship? = nil, actionHandler: MastodonPostMenuActionHandler? = nil, translation: Mastodon.Entity.Translation? = nil) {
        self.initialDisplayInfo = initialDisplay
    }
    
    func update(from actionablePost: GenericMastodonPost) throws {
        self.fullPost = try fullPost?.byReplacingActionablePost(with: actionablePost)
    }
    
    func hasCalculatedForWidth(_ width: CGFloat) -> Bool {
        if (isShowingTranslation != true) {
         return originalContentDisplayInfo?.hasCalculatedForWidth(width) == true
        }
        return translatedContentDisplayInfo?.hasCalculatedForWidth(width) == true
    }
    
    var altTextTranslations: [String : String]? {
        guard isShowingTranslation == true else { return nil }
        guard let attachmentTranslations = translation?.mediaAttachments else { return nil }
        
        let dictionary = attachmentTranslations.reduce(into: [ String : String]()) { partialResult, attachment in
            partialResult[attachment.id] = attachment.description
        }
        return dictionary
    }
    
    var pollOptionTranslations: [String]? {
        guard isShowingTranslation == true else { return nil }
        guard let pollTranslation = translation?.poll else { return nil }
        return pollTranslation.options.map { $0.title }
    }
    
    func openThreadView() {
        guard let actionablePost = fullPost?.actionablePost, let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
        actionHandler?.presentScene(
            .thread(
                viewModel: ThreadViewModel(
                    authenticationBox: currentUser,
                    optionalRoot: .root(
                        context: .init(
                            status: MastodonStatus(
                                entity: actionablePost._legacyEntity,
                                showDespiteContentWarning:
                                    false))))), fromPost: initialDisplayInfo.id, transition: .show)
    }
    
    func openURL(_ url: URL) -> Bool {
        if let mention = fullPost?.actionablePost?.content.htmlWithEntities?.mentions.first(where: { $0.url == url.absoluteString }) {
            goToProfile(mention)
            return true
        } else if let hashtag = fullPost?.actionablePost?.content.htmlWithEntities?.tags.first(where: { $0.name.lowercased() == url.lastPathComponent.lowercased() && url.pathComponents.contains("tags") }) {
            guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return false }
            let hashtagTimelineViewModel = HashtagTimelineViewModel(authenticationBox: currentUser, hashtag: hashtag.name)
            actionHandler?.presentScene(.hashtagTimeline(viewModel: hashtagTimelineViewModel), fromPost: initialDisplayInfo.id, transition: .show)
            return true
        } else {
            // fix non-ascii character URL link can not open issue
            actionHandler?.presentScene(.safari(url: url), fromPost: initialDisplayInfo.id, transition: .safariPresent(animated: true, completion: nil))
            return true
        }
    }
    
    func goToProfile(_ account: MastodonAccount) {
        guard let myRelationshipToAuthor else { return }
        switch myRelationshipToAuthor {
        case .isMe:
            let profile: ProfileViewController.ProfileType = .me(account._legacyEntity)
            actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
        case .isNotMe(let info):
            if let info, let me = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount {
                let profile: ProfileViewController.ProfileType = .notMe(me: me, displayAccount: account._legacyEntity, relationship: info._legacyEntity)
                actionHandler?.presentScene(.profile(profile), fromPost: initialDisplayInfo.id, transition: .show)
            }
        }
    }
    
    func goToProfile(_ mention: Mastodon.Entity.Mention) {
        Task {
            guard let currentUser = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
            let account = try await APIService.shared.accountInfo(
                domain: currentUser.domain,
                userID:
                    mention.id,
                authorization: currentUser.userAuthorization
            )
            goToProfile(MastodonAccount.fromEntity(account))
        }
    }
}

fileprivate extension MastodonPostViewModel {
    
    var socialContextHeader: SocialContextHeader? {
        guard let fullPost else { return nil }
        if fullPost is MastodonBoostPost {
            // BOOSTED BY
            return .boosted(by: fullPost.metaData.author.displayInfo.displayName, emojis: fullPost.metaData.author.displayInfo.emojis)
        } else if let basicPost = fullPost as? MastodonBasicPost {
            // REPLIED and/or PRIVATE MENTION
            let isPrivate = basicPost.metaData.privacyLevel == .mentionedOnly
            let replyInfo = basicPost.inReplyTo
            if let replyInfo {
                let replyToAccount = actionHandler?.account(replyInfo.accountID)
                return .reply(to: replyToAccount?.displayInfo.displayName ?? "unknown", isPrivate: isPrivate, isNotification: false, emojis: replyToAccount?.displayInfo.emojis ?? [])
            } else if isPrivate {
                return .mention(isPrivate: true)
            }
        }
        return nil
    }

    func textContentView() -> MastodonContentView {
        let emptyTextContent: MastodonContentView = .timelinePost(heightCacheID: "empty", html: "", emojis: MastodonContentView.Emojis(), isInlinePreview: false)
        
        guard let actionablePost = fullPost?.actionablePost, let untranslatedContent = actionablePost.content.htmlWithEntities?.html else { return emptyTextContent }
        let emojis = actionablePost.content.htmlWithEntities?.emojis ?? MastodonContentView.Emojis()
        
        if isShowingTranslation == true, let translation = actionHandler?.translation(forContentPostId: actionablePost.id)?.content {
            return .timelinePost(heightCacheID: actionablePost.id+"translated", html: translation, emojis: emojis, isInlinePreview: false)
        } else {
            return .timelinePost(heightCacheID: actionablePost.id, html: untranslatedContent, emojis: emojis, isInlinePreview: false)
        }
    }

    var hashtagComponent: PostViewComponent? {
        return .hashtags(["needs_implementation"])
    }
}

extension HomeTimelineListViewModel: MastodonPostMenuActionHandler {
    var mediaPreviewableViewController: (any MediaPreviewableViewController)? {
        return hostingViewController
    }
    
    func vote(poll: MastodonSDK.Mastodon.Entity.Poll, choices: [Int], containingPostID: Mastodon.Entity.Status.ID) async throws -> Mastodon.Entity.Poll {
        guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
        let updatedPoll = try await APIService.shared.vote(poll: poll, choices: choices, authenticationBox: authenticatedUser).value
        let updatedContainingStatus = try await APIService.shared.status(statusID: containingPostID, authenticationBox: authenticatedUser).value
        feedLoader?.updatePost(post: GenericMastodonPost.fromStatus(updatedContainingStatus))
        return updatedPoll
    }
    
    func showOverlay(_ overlay: MastodonTimelineOverlayView?) {
        activeOverlay = overlay
    }
    
    func presentScene(_ scene: SceneCoordinator.Scene, fromPost postID: Mastodon.Entity.Status.ID?, transition: SceneCoordinator.Transition) {
        if let postID {
            lastReadState = .interactedWith(postID)
        }
        parentVcPresentScene?(scene, transition)
    }
    
    func account(_ id: Mastodon.Entity.Account.ID) -> MastodonAccount? {
        return feedLoader?.account(id)
    }
    
    func doAction(_ action: MastodonPostMenuAction, forPost post: MastodonContentPost) {
        
        // Check not currently performing an action.
        guard isPerformingPostAction == nil && isPerformingAccountAction == nil else { return }
        
        guard let authenticatedUser, let actionablePost = post.actionablePost else { return }

        let author = actionablePost.metaData.author
        let relationshipInfo = myRelationship(to: author).info
        
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
                    guard let actionablePost = post.actionablePost else { throw PostActionFailure.noActionablePostId }
                    let statusEntityToReplyTo = try await APIService.shared.status(statusID: actionablePost.id, authenticationBox: authenticatedUser).value
                    let composeViewModel = ComposeViewModel(
                        authenticationBox: authenticatedUser,
                        composeContext: .composeStatus,
                        destination: .reply(parent: MastodonStatus(entity: statusEntityToReplyTo, showDespiteContentWarning: true)),
                        completion: { success in
                            // refetch this post to update the reply button
                            if success {
                                self.refetchAndDisplay(actionablePostID: actionablePost.id)
                            }
                        }
                    )
                    presentScene(.compose(viewModel: composeViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
                case .boost:
                    Task {
                        await boost(actionablePost.id, askFirst: UserDefaults.standard.askBeforeBoostingAPost)
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
                        feedLoader?.updatePost(post: GenericMastodonPost.fromStatus(updated))
                    }
                    clearPendingActions()
                    
            // MARK: TRANSLATE
                case .translatePost:
                    try await getTranslation(forPost: actionablePost)
                    feedLoader?.updateCachedResults({ timeline in
                        for item in timeline.items {
                            switch item {
                            case .loadingIndicator, .missingPosts:
                                break
                            case .post(let viewModel):
                                viewModel.isShowingTranslation = true
                            }
                        }
                    })
                case .showOriginalLanguage:
                    feedLoader?.updateCachedResults({ timeline in
                        for item in timeline.items {
                            switch item {
                            case .loadingIndicator, .missingPosts:
                                break
                            case .post(let viewModel):
                                viewModel.isShowingTranslation = false
                            }
                        }
                    })
                    
            // MARK: EDIT
                case .editPost:
                    guard let actionablePost = post.actionablePost else { throw PostActionFailure.noActionablePostId }
                    let statusEntityToEdit = try await APIService.shared.status(statusID: actionablePost.id, authenticationBox: authenticatedUser).value
                    let statusSourceToEdit = try await APIService.shared.getStatusSource(
                        forStatusID: actionablePost.id,
                        authenticationBox: authenticatedUser
                    ).value
                    
                    let editStatusViewModel = ComposeViewModel(
                        authenticationBox: authenticatedUser,
                        composeContext: .editStatus(status: MastodonStatus(entity: statusEntityToEdit, showDespiteContentWarning: true), statusSource: statusSourceToEdit),
                        destination: .topLevel, completion: { success in
                            // refetch the post to display the edits
                            if success {
                                self.refetchAndDisplay(actionablePostID: statusEntityToEdit.id)
                            }
                        })
                    presentScene(.editStatus(viewModel: editStatusViewModel), fromPost: nil, transition: .modal(animated: true))
                    
            // MARK: POST ACTIONS
                case .copyLinkToPost:
                    guard let urlString = post.actionablePost?.metaData.url else { throw PostActionFailure.noActionablePostId }
                    UIPasteboard.general.string = urlString
                    
                case .openPostInBrowser:
                    guard let urlString = post.actionablePost?.metaData.url, let url = URL(string: urlString) else { throw PostActionFailure.noActionablePostId }
                    presentScene(.safari(url: url), fromPost: nil, transition: .safariPresent(animated: true))
                    
                case .sharePost:
                    sharePost(actionablePost)

            // MARK: RELATIONSHIP ACTIONS
                    
                case .follow:
                    guard relationshipInfo?.canFollow == true else { throw PostActionFailure.noRelationshipInfo }
                    Task {
                        await commitFollow(author.id)
                    }
                    
                case .unfollow:
                    await doUnfollow(author, askFirst: UserDefaults.standard.askBeforeUnfollowingSomeone)

                case .mute:
                    activeAlert = .confirmMute(username: author.displayInfo.displayName, didConfirm: { [weak self] in
                        Task {
                            await self?.commitMute(author.id)
                        }
                    })
                    
                case .unmute:
                    activeAlert = .confirmUnmute(username: author.displayInfo.displayName, didConfirm: { [weak self] in
                        Task {
                            await self?.commitUnmute(author.id)
                        }
                    })
                    
            // MARK: DEFENSIVE ACTIONS
                case .blockUser:
                    activeAlert = .confirmBlock(username: author.displayInfo.displayName, didConfirm: { [weak self] in
                        Task {
                            await self?.commitBlock(author.id)
                        }
                    })
                    
                case .unblockUser:
                    activeAlert = .confirmUnblock(username: author.displayInfo.displayName, didConfirm: { [weak self] in
                        Task {
                            await self?.commitUnblock(author.id)
                        }
                    })
                    
                case .reportUser:
                    guard let relationship = try await APIService.shared.relationship(forAccountIds: [author.id], authenticationBox: authenticatedUser).value.first else { throw PostActionFailure.noRelationshipInfo }
                    let accountToReport = try await APIService.shared.accountInfo(domain: authenticatedUser.domain, userID: author.id, authorization: authenticatedUser.userAuthorization)
                    
                    let statusEntity: Mastodon.Entity.Status?
                    if let postIdToReport = post.actionablePost?.id {
                        statusEntity = try? await APIService.shared.status(statusID: postIdToReport, authenticationBox: authenticatedUser).value
                    } else {
                        statusEntity = nil
                    }
                    
                    let reportViewModel = ReportViewModel(
                        context: AppContext.shared,
                        authenticationBox: authenticatedUser,
                        account: accountToReport,
                        relationship: relationship,
                        status: statusEntity == nil ? nil : MastodonStatus(entity: statusEntity!, showDespiteContentWarning: true),
                        contentDisplayMode: .neverConceal
                    )
                    presentScene(.report(viewModel: reportViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
                    
            // MARK: DELETE
                case .deletePost:
                    guard let postID = post.actionablePost?.id else { throw PostActionFailure.noActionablePostId }
                    await deletePost(postID, askFirst: UserDefaults.shared.askBeforeDeletingAPost)
                }
            } catch {
                // TODO: handle error in a way the user can see it
                assertionFailure()
                clearPendingActions()
            }
        }
    }

    func canTranslate(post: MastodonContentPost) -> Bool {
        guard let postLanguage = post.content.language else { return false }
        guard let deviceLanguage = Bundle.main.preferredLocalizations.first else { return false }
        guard deviceLanguage != postLanguage else { return false }
    
        return instanceConfiguration?.canTranslateFrom(
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
            let updated = GenericMastodonPost.fromStatus(status)
            self?.feedLoader?.updatePost(post: updated)
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
    func boost(_ actionablePostId: Mastodon.Entity.Status.ID, askFirst: Bool) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            
            if askFirst {
                activeAlert = .confirmBoostOfPost(didConfirm: {
                    Task {
                        await self.boost(actionablePostId, askFirst: false)
                    }
                })
            } else {
                let updated = try await APIService.shared.boost(boostableStatusId: actionablePostId, authenticationBox: authenticatedUser) // this returns a new post, which is the boost action
                let updatedActionable = updated.reblog ?? updated // when updating the existing records, we only care about the original post
                feedLoader?.updatePost(post: GenericMastodonPost.fromStatus(updatedActionable))
                clearPendingActions()
            }
        } catch {
            // TODO: make visible to user
            clearPendingActions()
        }
    }
    
    // RELATIONSHIP ACTIONS
    
    func doUnfollow(_ author: MastodonAccount, askFirst: Bool) async {
        do {
            if askFirst {
                activeAlert = .confirmUnfollow(username: author.displayInfo.displayName, didConfirm: { [weak self] in
                    Task {
                        await self?.doUnfollow(author, askFirst: false)
                    }
                })
            } else {
                guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
                let response = try await APIService.shared.unfollow(author.id, authenticationBox: authenticatedUser)
                let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
                feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: author.id)
                AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
            }
        } catch {
            // TODO: make visible to user
            assert(false)
        }
        isPerformingAccountAction = nil
    }
    
    func commitFollow(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.follow(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: accountID)
            AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
        } catch {
            // TODO: make visible to user
        }
        isPerformingAccountAction = nil
    }
    
    func commitMute(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.mute(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: accountID)
            AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
        } catch {
            // TODO: make visible to user
        }
        isPerformingAccountAction = nil
    }
    
    func commitUnmute(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unmute(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: accountID)
            AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
        } catch {
            // TODO: make visible to user
        }
        isPerformingAccountAction = nil
    }
     
    // DEFENSIVE ACTIONS
    
    func commitBlock(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.block(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: accountID)
            AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
        } catch {
            // TODO: make visible to user
        }
        isPerformingAccountAction = nil
    }
    
    func commitUnblock(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unblock(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: accountID)
            AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
        } catch {
            // TODO: make visible to user
        }
        isPerformingAccountAction = nil
    }
    
    func deletePost(_ postID: Mastodon.Entity.Status.ID, askFirst: Bool) async {
        do {
            if askFirst {
                activeAlert = .confirmDeleteOfPost(didConfirm: {
                    Task {
                        await self.deletePost(postID, askFirst: false)
                    }
                })
            } else {
                guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
                let deletedStatus = try await APIService.shared.deleteContentPost(postID, authenticationBox: authenticatedUser)
                feedLoader?.didDeletePost(deletedStatus.id)
                self.clearPendingActions()
            }
        } catch {
            self.clearPendingActions()
            // TODO: make visible to user
        }
    }
    
    func sharePost(_ actionablePost: MastodonContentPost) {
        let activityItems: [Any] = {
            guard let url = URL(string: actionablePost.metaData.url ?? actionablePost.metaData.uriForFediverse) else { return [] }
            return [
                URLActivityItem(url: url)
            ]
        }()

        let activityViewController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        presentScene(
            .activityViewController(
                activityViewController: activityViewController,
                sourceView: nil,
                barButtonItem: nil
            ),
            fromPost: nil,
            transition: .activityViewControllerPresent(animated: true, completion: nil)
        )
    }
    
}

extension GenericMastodonPost {
    var actionablePost: MastodonContentPost? {
        let actionablePost: MastodonContentPost?
        if let contentPost = self as? MastodonContentPost {
            actionablePost = contentPost
        } else if let boost = self as? MastodonBoostPost {
            actionablePost = boost.boostedPost
        } else {
            assertionFailure("not implemented")
            actionablePost = nil
        }
        return actionablePost
    }
}

struct TranslationInfoView: View {
    let translationInfo: Mastodon.Entity.Translation
    let showOriginal: ()->()
    
    var body: some View {
        HStack(alignment: .top) {
            Text(translatedFromLanguageByProvider)
                .lineLimit(1)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button {
                showOriginal()
            } label: {
                Text(L10n.Common.Controls.Status.Translation.showOriginal)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundStyle(Asset.Colors.Brand.blurple.swiftUIColor)
            }
            .fixedSize()
        }
    }
    
    var translatedFromLanguageByProvider: String {
        let languageName = languageName(translationInfo.sourceLanguage) ?? L10n.Common.Controls.Status.Translation.unknownLanguage
        return L10n.Common.Controls.Status.Translation.translatedFrom(languageName, translationInfo.provider ?? L10n.Common.Controls.Status.Translation.unknownProvider)
    }
}

extension ContentConcealViewModel {
    func buttonText(whenHiding: Bool) -> String? {
        switch currentMode {
        case .neverConceal, .concealMediaOnly:
            return nil
        case .concealAll:
            if currentModeIsFilter {
                return whenHiding ? L10n.Common.Controls.Status.showAnyway : L10n.Common.Controls.Status.Actions.hide
            } else {
                return whenHiding ? L10n.Common.Controls.Status.showMore : L10n.Common.Controls.Status.Actions.hide
            }
        }
    }
}

struct GapLoaderView: View {
    let newerThan: String
    let olderThan: String
    let gapDescription: String
    let loadFromTop: ()->()
    let loadFromBottom: ()->()
    
    var body: some View {
        HStack {
            
            VStack {
                Button {
                    loadFromTop()
                } label: {
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.title2)
                        .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                }
                .buttonStyle(.borderless)
                
                Spacer()
                    .frame(minHeight: standardPadding, maxHeight: .infinity)
            }
            
            Spacer()
                .frame(maxWidth: .infinity)
            
            VStack {
                Text(L10n.Common.Controls.Timeline.Loader.loadMissingPosts)
                    .lineLimit(1)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("older than: \(olderThan)")
                    .lineLimit(1)
                    .fixedSize()
                    .font(.footnote)
                Text("newer than: \(newerThan)")
                    .lineLimit(1)
                    .fixedSize()
                    .font(.footnote)
                Text(gapDescription)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
                .frame(maxWidth: .infinity)
            
            VStack {
                Spacer()
                    .frame(minHeight: standardPadding, maxHeight: .infinity)
                
                Button {
                    loadFromBottom()
                } label: {
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.title2)
                        .foregroundStyle(Asset.Colors.accent.swiftUIColor)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
