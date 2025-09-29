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

enum TimelineViewType {
    case home
    case notifications(NotificationsScope)
    case trendingPosts
    case myBookmarks
    case myFavorites
    case searchPosts(String)
    case profilePosts(tabTitle: String?, userID: String, queryFilter: TimelineQueryFilter)
    case thread(root: MastodonContentPost)
    case remoteThread(root: RemoteThreadType)
    
    var tabTitle: String? {
        switch self {
        case .profilePosts(let tabTitle, _, _):
            return tabTitle
        default:
            return nil
        }
    }
}

class TimelineListViewController: UIHostingController<TimelineListView>
{
    public let type: TimelineViewType
    private let viewModel: TimelineListViewModel
    private var navigationFlow: NavigationFlow?
    private let _mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    private var scrollToTopUpdateSubscription: AnyCancellable?
    
    init(_ type: TimelineViewType) {
        self.type = type
        switch type {
        case .home:
            viewModel = TimelineListViewModel(timeline: .following)
        case .notifications(let scope):
            viewModel = TimelineListViewModel(timeline: .notifications(scope: scope))
        case .trendingPosts:
            viewModel = TimelineListViewModel(timeline: .discovery)
        case .searchPosts(let searchText):
            viewModel = TimelineListViewModel(timeline: .search(searchText))
        case .profilePosts(_, let user, let queryFilter):
            viewModel = TimelineListViewModel(timeline: .userPosts(userID: user, queryFilter: queryFilter))
        case .thread(let root):
            viewModel = TimelineListViewModel(timeline: .thread(root: root))
        case .remoteThread(let remoteThreadType):
            viewModel = TimelineListViewModel(timeline: .remoteThread(remoteType: remoteThreadType))
        case .myBookmarks:
            viewModel = TimelineListViewModel(timeline: .myBookmarks)
        case .myFavorites:
            viewModel = TimelineListViewModel(timeline: .myFavorites)
        }
        let root = TimelineListView(viewModel: viewModel)
        super.init(rootView: root)
        viewModel.parentVcPresentScene = { (scene, transition) in
            self.sceneCoordinator?.present(scene: scene, from: self, transition: transition)
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
        
        switch type {
        case .home:
            setUpTimelineSelectorButton()
            setUpScrollToTop()
            showSettingsButton(true)
        case .notifications:
            setUpNotificationsNavBarControls()
            if viewModel.timeline.canDisplayFilteredNotifications {
                NotificationCenter.default.addObserver(self, selector: #selector(notificationFilteringPolicyDidChange), name: .notificationFilteringChanged, object: nil)
            }
        case .thread(let focusedPost):
            let authorHandle = focusedPost.initialDisplayInfo(inContext: .thread).actionableAuthorHandle
            navigationItem.title = L10n.Scene.Thread.title("@\(authorHandle)")
        default:
            break
        }
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
    
    lazy var picker = { UISegmentedControl(items: [ NotificationsScope.everything.pickerLabel, NotificationsScope.mentions.pickerLabel ]) }()
    
    var scrollToTopButton: UIButton?
    
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
    
    func notificationAcceptRejectMenuButton(forRequest request: Mastodon.Entity.NotificationRequest) -> UIButton {
        let button = UIButton(type: .custom)
        
        let imageConfiguration = UIImage.SymbolConfiguration(paletteColors: [.label])
            .applying(UIImage.SymbolConfiguration(textStyle: .subheadline))
            .applying(UIImage.SymbolConfiguration(pointSize: 16, weight: .bold, scale: .medium))
        
        button.configuration = {
            var config = UIButton.Configuration.plain()
            config.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
            config.imagePadding = 8
            config.image = UIImage(systemName: "ellipsis", withConfiguration: imageConfiguration)
            config.imagePlacement = .trailing
            return config
        }()
        
        button.showsMenuAsPrimaryAction = true
        button.menu = generateNotificationRequestMenu(request)
        return button
    }
}

extension TimelineListViewController {
    // MARK: HomeTimeline Nav Bar controls
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
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let setting = SettingService.shared.currentSetting.value else { return }
        
        _ = self.sceneCoordinator?.present(scene: .settings(setting: setting), from: self, transition: .none)
    }
    
    func showSettingsButton(_ show: Bool) {
        if show {
            self.navigationItem.rightBarButtonItem = settingBarButtonItem
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    func setUpTimelineSelectorButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: timelineSelectorButton)
    }
    
    private func generateTimelineSelectorMenu() -> UIMenu {
        let useLazyVStackAction: UIAction
        if viewModel.useLazyVStack {
            useLazyVStackAction = UIAction(title: "Using LazyVStack") { [weak self] _ in
                guard let self else { return }
                viewModel.useLazyVStack = false
                timelineSelectorButton.menu = generateTimelineSelectorMenu()
            }
        } else {
            useLazyVStackAction = UIAction(title: "Using VStack") { [weak self] _ in
                guard let self else { return }
                viewModel.useLazyVStack = true
                timelineSelectorButton.menu = generateTimelineSelectorMenu()
            }
        }
        
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
        case .discovery, .search, .userPosts, .thread, .remoteThread, .myBookmarks, .myFavorites, .notifications:
            assertionFailure()
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
        
//        if UserDefaults.isDebugOrTestflightOrSimulator {
//            return UIMenu(children: [useLazyVStackAction, showFollowingAction, showLocalTimelineAction, listsDivider])
//        } else {
        return UIMenu(children: [showFollowingAction, showLocalTimelineAction, listsDivider])
//        }
        
    }
    
    private func generateNotificationRequestMenu(_ request: Mastodon.Entity.NotificationRequest) -> UIMenu {
        let acceptAction = UIAction(title: L10n.Scene.Notification.FilteredNotification.accept, image: .init(systemName: "checkmark")) { [weak self] _ in
            Task {
                do {
                    try await self?.acceptNotificationRequest(request)
                } catch {
                    self?.viewModel.didReceiveError(error)
                }
            }
        }
        
        let rejectAction = UIAction(title: L10n.Scene.Notification.FilteredNotification.dismiss, image: .init(systemName: "trash")) { [weak self] _ in
            Task {
                do {
                    try await self?.rejectNotificationRequest(request)
                } catch {
                    self?.viewModel.didReceiveError(error)
                }
            }
        }
        
        let acceptRejectMenu = UIMenu(children: [acceptAction, rejectAction])
        return acceptRejectMenu
    }
    
    private func acceptNotificationRequest(_ notificationRequest: MastodonSDK.Mastodon.Entity.NotificationRequest) async throws {
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
        _ = try await APIService.shared.acceptNotificationRequests(authenticationBox: authBox, id: notificationRequest.id)
        NotificationCenter.default.post(name: .notificationFilteringChanged, object: nil)
    }
    
    private func rejectNotificationRequest(_ notificationRequest: MastodonSDK.Mastodon.Entity.NotificationRequest) async throws {
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
        _ = try await APIService.shared.rejectNotificationRequests(authenticationBox: authBox, id: notificationRequest.id)
        NotificationCenter.default.post(name: .notificationFilteringChanged, object: nil)
    }
}

extension NotificationsScope {
    var pickerLabel: String {
        switch self {
        case .everything:
            L10n.Scene.Notification.Title.everything
        case .mentions:
            L10n.Scene.Notification.Title.mentions
        case .fromRequest:
            ""
        }
    }
}

extension TimelineListViewController {
    // MARK: Notifications Nav Bar controls
    
    func setUpNotificationsNavBarControls() {
        switch viewModel.timeline {
        case .notifications(.everything), .notifications(.mentions):
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "line.3.horizontal.decrease.circle"), style: .plain, target: self, action: #selector(showNotificationPolicySettings))
            
            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.selectedSegmentIndex = 0
            navigationItem.titleView = picker
            NSLayoutConstraint.activate([
                picker.widthAnchor.constraint(greaterThanOrEqualToConstant: 287)
            ])
            picker.addTarget(self, action: #selector(pickerValueChanged(_:)), for: .valueChanged)
        case .notifications(.fromRequest(let request)):
            navigationItem.title = "@\(request.account.handle)"
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: notificationAcceptRejectMenuButton(forRequest: request))
        default:
            break
        }
    }
    
    @objc private func pickerValueChanged(_ sender: UISegmentedControl) {
        let newScope: NotificationsScope
        switch sender.selectedSegmentIndex {
        case 0:
            newScope = .everything
        case 1:
            newScope = .mentions
        default:
            newScope = .everything
        }
        switch viewModel.timeline {
        case .notifications(let scope):
            if scope != newScope {
                viewModel.resetToUntrackedAfterDelay()
                viewModel.timeline = .notifications(scope: newScope)
            }
        default:
            break
        }
    }
    
    @objc private func showNotificationPolicySettings(_ sender: Any) {
        guard let policy = viewModel.filteredNotificationsViewModel.policy else { return }
        Task {
            let adminSettings: AdminNotificationFilterSettings? = await {
                guard let user = AuthenticationServiceProvider.shared.currentActiveUser.value, let role = user.cachedAccount?.role else { print("no role"); return nil }
                let permissions = role.rolePermissions()
                let hasAdminPermissions = permissions.contains(.administrator) || permissions.contains(.manageReports) || permissions.contains(.manageUsers)
                guard hasAdminPermissions else { print("no permissions"); return nil }
                if let existingPreferences = await BodegaPersistence.Notifications.currentPreferences(for: user.authentication) {
                    return existingPreferences
                } else {
                    return AdminNotificationFilterSettings(forReports: .accept, forSignups: .accept)
                }
            }()
            
            let policyViewModel = await NotificationPolicyViewModel(
                NotificationFilterSettings(
                    forNotFollowing: policy.forNotFollowing,
                    forNotFollowers: policy.forNotFollowers,
                    forNewAccounts: policy.forNewAccounts,
                    forPrivateMentions: policy.forPrivateMentions,
                    forLimitedAccounts: policy.forLimitedAccounts
                ),
                adminSettings: adminSettings
            )
            
            guard let policyViewController = self.sceneCoordinator?.present(scene: .notificationPolicy(viewModel: policyViewModel), transition: .formSheet(policyViewModel.adminFilterSettings != nil ? [.large()] : nil)) as? NotificationPolicyViewController else { return }
            
            policyViewController.delegate = self
        }
    }
}

extension TimelineListViewController: NotificationPolicyViewControllerDelegate {
    func policyUpdated(_ viewController: NotificationPolicyViewController, newPolicy: MastodonSDK.Mastodon.Entity.NotificationPolicy) {
        viewModel.updateFilteredNotificationsPolicy(newPolicy, andReloadFeed: true)
    }
    
    @objc func notificationFilteringPolicyDidChange(_ notification: Notification) {
        viewModel.fetchFilteredNotificationsPolicy(andReloadFeed: true)
    }
}

extension TimelineListViewController: MediaPreviewableViewController {
    var mediaPreviewTransitionController: MediaPreviewTransitionController {
        return _mediaPreviewTransitionController
    }
}

extension MastodonPostMenuAction {
    enum AlertType {
        case noAlert
        case confirmBoostOfPost(didConfirm: (Bool)->())
        case confirmDeleteOfPost(didConfirm: (Bool)->())
        case confirmUnfollow(username: String, didConfirm: (Bool)->())
        case confirmMute(username: String, didConfirm: (Bool)->())
        case confirmUnmute(username: String, didConfirm: (Bool)->())
        case confirmRemoveQuote(username: String, didConfirm: (Bool)->())
        case confirmBlock(username: String, didConfirm: (Bool)->())
        case confirmUnblock(username: String, didConfirm: (Bool)->())
        case error(Error)
        
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
                
            case .confirmRemoveQuote:
                L10n.Common.Alerts.ConfirmRemoveQuote.title
            case .confirmBlock:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmBlockUser.title
            case .confirmUnblock:
                L10n.Scene.Profile.RelationshipActionAlert.ConfirmUnblockUser.title
            case .error:
                L10n.Common.Alerts.genericError
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
                
            case .confirmRemoveQuote:
                L10n.Common.Alerts.ConfirmRemoveQuote.message
            case .confirmDeleteOfPost:
                L10n.Common.Alerts.DeletePost.message
            case .error(let error):
                error.localizedDescription
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

enum MastodonTimelineSheet {
    case postInteractionSettingsEdit(PostInteractionSettingsViewModel)
    case boostOrQuoteDialog(MastodonPostViewModel)
}

@MainActor
private class TimelineListViewModel: ObservableObject {
    
    enum ReloadReason {
        case notificationFilterPolicyUpdated
        case userRequestedRefresh
        case notificationCountUpdated
    }
    
    public var parentVcPresentScene: ((SceneCoordinator.Scene, SceneCoordinator.Transition) -> ())?
    public var presentDonationDialog: ((Mastodon.Entity.DonationCampaign) -> ())?
    @Published private(set) var authenticatedUser: MastodonAuthenticationBox? = AuthenticationServiceProvider.shared.currentActiveUser.value
    
    var instanceConfigurationUpdateSubscription: AnyCancellable?

    var hostingViewController: MediaPreviewableViewController?
    
    var filteredNotificationsViewModel =
        FilteredNotificationsRowView.ViewModel(policy: nil)
    var needsReloadOnNextAppear = false
    
    var errorsWaitingToDisplay = [Error]()
    var activeAlert: MastodonPostMenuAction.AlertType = .noAlert {
        didSet {
            if !isPresentingAlert && activeAlert.shouldBePresented {
                isPresentingAlert = true
            }
            displayNextErrorIfPossible()
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
    var activeSheet: MastodonTimelineSheet? = nil {
        didSet {
            if !isShowingSheet && activeSheet != nil {
                isShowingSheet = true
            } else if isShowingSheet && activeSheet == nil {
                isShowingSheet = false
            }
        }
    }
    
    @Published var isShowingOverlay: Bool = false
    @Published var isShowingSheet: Bool = false
    @Published var isPresentingAlert: Bool = false
    @Published var presentedDonationCampaign: Mastodon.Entity.DonationCampaign?
    
    @Published var isPerformingPostAction: (action: MastodonPostMenuAction, post: MastodonContentPost)? = nil
    @Published var isPerformingAccountAction: (action: MastodonPostMenuAction, account: MastodonAccount)? = nil
    
    @Published var feedIsEmpty: Bool = false
    
    @Published var useLazyVStack: Bool = false
    
    @Published var currentDisplaySlice = ArraySlice<TimelineItem>()
    func setCurrentDisplaySlice(_ newSlice: ArraySlice<TimelineItem>) {
        // space to add any necessary bookkeeping before setting the slice
        switch timeline {
        case .notifications(.everything), .notifications(.mentions):
            if newSlice.startIndex == 0 {
                self.currentDisplaySlice = [.filteredNotificationsInfo(filteredNotificationsViewModel.policy, filteredNotificationsViewModel)] + newSlice
            } else {
                self.currentDisplaySlice = newSlice
            }
        default:
            self.currentDisplaySlice = newSlice
        }
    }
    
    private var fullFeed = MastodonFeedLoaderResult(allRecords: [TimelineItem](), canLoadOlder: false)
    private let displaySliceLength = 100
    
    @Published var unreadCount: Int = 0
    @Published var scrollToTopRequested: Bool = false
    
    private var followersAndBlockedChangeSubscription: AnyCancellable?
    private var feedLoader: TimelineFeedLoader?
    private var feedLoaderResultsSubscription: AnyCancellable?
    private var feedLoaderErrorSubscription: AnyCancellable?
    private var notificationCountUpdateSubscription: AnyCancellable?
    
    var scrollManager: ScrollManager?
    
    private let displayPrepBatchSize = 10
    private var currentlyPreparingForDisplay: [String]?
    private var displayPrepRequested: [MastodonPostViewModel]? // only keep the latest batch requested, to avoid getting bogged down while fast scrolling
    
    public var lastReadState: LastReadState = .initializing
    
    public var threadedConversationModel: ThreadedConversationModel? {
        return feedLoader?.threadedConversationModel
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
        if activeSheet != nil {
            activeSheet = nil
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
            lastReadState = .untracked
            currentDisplaySlice = ArraySlice([.loadingIndicator])
            fullFeed = MastodonFeedLoaderResult(allRecords: [], canLoadOlder: true)
            Task {
                try await doInitialLoad()
            }
        }
    }
    
    init(timeline: MastodonTimelineType) {
        self.timeline = timeline
        
        self.instanceConfigurationUpdateSubscription = AuthenticationServiceProvider.shared.instanceConfigurationUpdates
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] updatedDomain in
                guard let self, self.authenticatedUser?.domain == updatedDomain else { return }
                self.authenticatedUser = AuthenticationServiceProvider.shared.currentActiveUser.value
            }
        
        Task {
            try await doInitialLoad()
        }
    }
    
    var isThreadView: Bool {
        return feedLoader?.threadedConversationModel != nil
    }
    
    private func getDisplaySlice(from items: [TimelineItem], startItemID: Mastodon.Entity.Status.ID?, canLoadOlder: Bool) -> ArraySlice<TimelineItem> {
        if useLazyVStack || isThreadView {
            return items[items.startIndex..<items.endIndex]
        } else {
            let startIndex = items.firstIndex(where: { $0.id == startItemID}) ?? 0
            let endIndex = min(startIndex + displaySliceLength, items.endIndex)
            return items[startIndex..<endIndex] + (endIndex != items.endIndex || canLoadOlder ? [.loadingIndicator] : [])
        }
    }
    
    private func getDisplaySlice(from items: [TimelineItem], midIndex: Int, canLoadOlder: Bool) -> ArraySlice<TimelineItem> {
        if useLazyVStack || isThreadView {
            return items[items.startIndex..<items.endIndex]
        } else {
            let startIndex = max(0, midIndex - (self.displaySliceLength / 2))
            let endIndex = min(startIndex + self.displaySliceLength, items.endIndex)
            return items[startIndex..<endIndex] + (endIndex < items.endIndex || canLoadOlder ? [.loadingIndicator] : [])
        }
    }
    
    private func getDisplaySlice(from items: [TimelineItem], endIndex: Int, canLoadOlder: Bool) -> ArraySlice<TimelineItem> {
        if useLazyVStack || isThreadView {
            return items[items.startIndex..<items.endIndex]
        } else {
            let startIndex = max(0, endIndex - self.displaySliceLength)
            let endIndex = min(startIndex + self.displaySliceLength, items.endIndex)
            return items[startIndex..<endIndex] + (endIndex < items.endIndex || canLoadOlder ? [.loadingIndicator] : [])
        }
    }
    
    func doInitialLoad() async throws {
        guard feedLoader == nil else { return }
        guard let authenticatedUser else { return }
        clearPendingActions()
        feedLoader = TimelineFeedLoader(currentUser: authenticatedUser, timeline: timeline)
        feedLoaderResultsSubscription = feedLoader?.$records
            .sink{ [weak self] results in
                
                guard results.allRecords.count > 0 || results.canLoadOlder else {
                    self?.feedIsEmpty = true
                    return
                }
                
                if self?.feedIsEmpty == true {
                    self?.feedIsEmpty = false
                }
                
                
                let needsPrep: [TimelineItem] = results.allRecords.compactMap { item -> TimelineItem? in
                    switch item {
                    case .loadingIndicator, .filteredNotificationsInfo:
                        return nil
                    case .post(let postViewModel):
                        return postViewModel.displayPrepStatus == .unprepared ? item : nil
                    case .notification(let notificationViewModel):
                        return notificationViewModel.displayPrepStatus == .unprepared ? item : nil
                    }
                }
                
                self?.doPrepareForDisplay(needsPrep, contentWidth: 0, completion: {
                    DispatchQueue.main.async {
                        guard let self else { return }
                        
                        debugScroll("doPrepareForDisplay is done")
                        
                        let currentFirstItemID = self.currentDisplaySlice.first(where: {
                            switch $0 {
                            case .post: return true
                            default: return false
                            }
                        })?.id
                        
                        let newDisplaySlice: ArraySlice<TimelineItem>?

                        if currentFirstItemID == nil {
                            // current timeline is empty, so take the top slice of these items to display
                            newDisplaySlice = self.getDisplaySlice(from: results.allRecords, startItemID: nil, canLoadOlder: results.canLoadOlder)
                            self.resetToUntrackedAfterDelay()
                        } else {
                            switch self.lastReadState {
                            case .initializing:
                                self.resetToUntrackedAfterDelay()
                                newDisplaySlice = nil // don't mess with the visible items
                            case .untracked:
                                newDisplaySlice = nil // don't mess with the visible items
                            case .requestedReloadFromBottom:
                                let lastCurrentItem = self.currentDisplaySlice.last(where: { $0.isRealItem })
                                newDisplaySlice = self.getDisplaySlice(from: results.allRecords, startItemID: lastCurrentItem?.id, canLoadOlder: results.canLoadOlder)
                            case .requestedReloadFromTop:
                                assertionFailure("reload from top should only cause a new slice to be taken from the already available feed")
                                if let firstCurrentItem = self.currentDisplaySlice.first(where: { $0.isRealItem}), let newIndex = results.allRecords.lastIndex(where: { $0.id == firstCurrentItem.id }) {
                                    newDisplaySlice = self.getDisplaySlice(from: results.allRecords, endIndex: newIndex, canLoadOlder: results.canLoadOlder)
                                } else {
                                 // possible that the new set of results doesn't include what we were just looking at; in that case, jump to the top
                                    newDisplaySlice = self.getDisplaySlice(from: results.allRecords, startItemID: nil, canLoadOlder: results.canLoadOlder)
                                }
                            case .pullToRefresh:
                                // jump to the top
                                newDisplaySlice = self.getDisplaySlice(from: results.allRecords, startItemID: nil, canLoadOlder: results.canLoadOlder)
                            }
                        }
                        if let newDisplaySlice {
                            self.fullFeed = results
                            self.setCurrentDisplaySlice(newDisplaySlice)
                        } else {
                            self.fullFeed = results
                        }
                    }
                })
            }
        
        feedLoaderErrorSubscription = feedLoader?.$currentError
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                guard let self, let error else { return }
                self.didReceiveError(error)
            }
        feedLoader?.doFirstLoad()
       
        if timeline.canDisplayFilteredNotifications {
            fetchFilteredNotificationsPolicy(andReloadFeed: false)
        }
        if timeline.canDisplayUnreadNotifications {
            notificationCountUpdateSubscription = NotificationService.shared.unreadNotificationCountDidUpdate
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    if UserDefaults.shared.notificationBadgeCount > 0 && self?.timeline.canDisplayUnreadNotifications == true {
                        self?.needsReloadOnNextAppear = true
                    }
                }
        }
        
        followersAndBlockedChangeSubscription = AuthenticationServiceProvider.shared.$didChangeFollowersAndFollowing.sink {
            [weak self] userID in
            guard userID == self?.authenticatedUser?.globallyUniqueUserIdentifier else { return }
            self?.feedLoader?.requestLoad(.reload)
        }
    }
    
    func didReceiveError(_ error: Error) {
        if errorsWaitingToDisplay.count < 3 {
            errorsWaitingToDisplay.append(error)
        }
        displayNextErrorIfPossible()
    }
    
    func displayNextErrorIfPossible() {
        guard let error = errorsWaitingToDisplay.first else { return }
        switch activeAlert {
        case .noAlert:
            activeAlert = .error(error)
            _ = errorsWaitingToDisplay.removeFirst()
        default:
            return
        }
    }
    
    func loadMoreFromBottom() {
        lastReadState = .requestedReloadFromBottom
        if currentDisplaySlice.endIndex < fullFeed.allRecords.endIndex {
            let scrollToTop = currentDisplaySlice.last(where: {
                $0.isRealItem
            })
            guard let scrollToTop else {
                debugScroll("could not find a tail item in the current slice")
                resetToUntrackedAfterDelay()
                return
            }
            setCurrentDisplaySlice(getDisplaySlice(from: fullFeed.allRecords, startItemID: scrollToTop.id, canLoadOlder: fullFeed.canLoadOlder))
        } else {
            guard let feedLoader else {
                // this is a valid state when switching between timelines
                resetToUntrackedAfterDelay()
                return
            }
            feedLoader.requestLoad(.older)
        }
    }
    
    func loadNewerSlice() {
        if currentDisplaySlice.startIndex > 0 {
            lastReadState = .requestedReloadFromTop
            let lastVisibleHeadIndex = currentDisplaySlice.firstIndex(where: { $0.isRealItem })
            guard let lastVisibleHeadIndex else {
                debugScroll("could not find a head index in the current slice")
                resetToUntrackedAfterDelay()
                return
            }
            setCurrentDisplaySlice(getDisplaySlice(from: fullFeed.allRecords, endIndex: lastVisibleHeadIndex, canLoadOlder: fullFeed.canLoadOlder))
        } else {
            resetToUntrackedAfterDelay()
        }
    }
    
    func refreshFromTop() async {
        assert(lastReadState == .pullToRefresh)
        if currentDisplaySlice.startIndex == 0 {
            await forceReload(.userRequestedRefresh)
        } else {
            lastReadState = .requestedReloadFromTop
            loadNewerSlice()
        }
    }
    
    func forceReload(_ reason: ReloadReason) async {
        guard let feedLoader else {
            resetToUntrackedAfterDelay()
            assertionFailure()
            return
        }
        needsReloadOnNextAppear = false
        switch reason {
        case .notificationCountUpdated:
            fetchFilteredNotificationsPolicy(andReloadFeed: true)
        case .notificationFilterPolicyUpdated:
            lastReadState = .pullToRefresh
            feedLoader.requestLoad(.reload)
        case .userRequestedRefresh:
            if timeline.canDisplayFilteredNotifications {
                fetchFilteredNotificationsPolicy(andReloadFeed: false)
            }
            if feedLoader.permissionToLoadImmediately {
                await feedLoader.loadImmediately(.reload)
                await feedLoader.clearCache() // reset the cache when user refreshes
                commitToCache()
            }
        }
    }
    
    func scrollToTop() {
        setCurrentDisplaySlice(getDisplaySlice(from: fullFeed.allRecords, startItemID: nil, canLoadOlder: fullFeed.canLoadOlder))
        scrollToTopRequested = true
    }
    
    func didAppear(_ postViewModel: MastodonPostViewModel, contentWidth: CGFloat) {
        guard currentDisplaySlice.endIndex < fullFeed.allRecords.endIndex || fullFeed.canLoadOlder == true else {
            debugScroll("have loaded as far back as possible")
            return
        }
        switch lastReadState {
        case .initializing:
            resetToUntrackedAfterDelay()
        case .untracked:
            break
        case .requestedReloadFromTop, .requestedReloadFromBottom, .pullToRefresh:
            debugScroll("head or tail item appeared.  ignoring because state is \(lastReadState)")
            break
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
    
    func suggestAccountsToFollow() {
        guard let authenticatedUser else { return }
        let suggestionAccountViewModel = SuggestionAccountViewModel(authenticationBox: authenticatedUser)
        presentScene(.suggestionAccount(viewModel: suggestionAccountViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
    }
}

extension TimelineListViewModel {
    func fetchFilteredNotificationsPolicy(andReloadFeed reload: Bool) {
        guard
            let authBox = AuthenticationServiceProvider.shared.currentActiveUser
                .value
        else { return }
        Task {
            let policy = try? await APIService.shared.notificationPolicy(
                authenticationBox: authBox)
            updateFilteredNotificationsPolicy(policy?.value, andReloadFeed: reload)
        }
    }
    
    func updateFilteredNotificationsPolicy(
        _ policy: Mastodon.Entity.NotificationPolicy?,
        andReloadFeed reload: Bool
    ) {
        guard filteredNotificationsViewModel.policy != policy else { return }
        filteredNotificationsViewModel.policy = policy
        guard reload else { return }
        
        switch lastReadState {
        case .initializing:
            break
        case .pullToRefresh, .requestedReloadFromBottom, .requestedReloadFromTop:
            break
        case .untracked:
            Task {
                await self.forceReload(.notificationFilterPolicyUpdated)
            }
        }
    }
}

extension TimelineListViewModel {
    private func createPrepBatch(anchoredAt anchorIndex: Int) -> [TimelineItem]? {
        guard let feedLoaderRecords = feedLoader?.records.allRecords else { return nil }
        let batchStart = max(0, anchorIndex - displayPrepBatchSize / 2)
        guard batchStart < feedLoaderRecords.count else { return nil }
        let batchItems = feedLoaderRecords[batchStart...].prefix(displayPrepBatchSize).compactMap { item -> TimelineItem? in
            switch item {
            case .loadingIndicator, .filteredNotificationsInfo:
                return nil
            case .post(let postViewModel):
                // not donePreparing, not included in currently preparing (inclusion in requested does not matter, because this batch may replace the current requested batch)
                guard postViewModel.displayPrepStatus == .unprepared else { return nil }
                return item
            case .notification(let notificationViewModel):
                guard notificationViewModel.displayPrepStatus == .unprepared else { return nil }
                return item
            }
        }
        
        guard !batchItems.isEmpty else { return nil }
        return batchItems
    }
    
    private func doPrepareForDisplay(_ batch: [TimelineItem], contentWidth: CGFloat, completion: (()->())? = nil) {
        guard let feedLoader else { completion?(); return }
        guard currentlyPreparingForDisplay == nil else { completion?(); return }
        currentlyPreparingForDisplay = batch.compactMap { item in
            switch item {
            case .post:
                return item.id
            case .notification:
                return item.id
            default:
                return nil
            }
        }
        
        var needsPrep = [MastodonPostViewModel]()
        var relationshipsToFetch = [Mastodon.Entity.Account.ID]()
        
        func processPostViewModel(_ postViewModel: MastodonPostViewModel) {
            if postViewModel.initialDisplayInfo.actionableAuthorId == authenticatedUser?.userID {
                postViewModel.myRelationshipToAuthor = .isMe
            } else {
                relationshipsToFetch.append(postViewModel.initialDisplayInfo.actionableAuthorId)
            }
            if let actionablePost = postViewModel.fullPost?.actionablePost, postViewModel.isShowingTranslation == nil {
                postViewModel.isShowingTranslation = canTranslate(post: actionablePost) ? false : nil
            }
        }
        
        for item in batch {
            switch item {
            case .post(let postModel):
                if postModel.displayPrepStatus == .unprepared {
                    needsPrep.append(postModel)
                }
                if let fullQuotedPostViewModel = postModel.fullQuotedPostViewModel {
                    needsPrep.append(fullQuotedPostViewModel)
                }
            case .notification(let notificationViewModel):
                if let embeddedPostModel = notificationViewModel.inlinePostViewModel {
                    needsPrep.append(embeddedPostModel)
                    if let fullQuotedPostViewModel = embeddedPostModel.fullQuotedPostViewModel {
                        needsPrep.append(fullQuotedPostViewModel)
                    }
                }
                if let needsRelationshipTo = notificationViewModel.needsRelationshipTo {
                    relationshipsToFetch.append(needsRelationshipTo.id)
                }
            default:
               break
            }
        }

        for postModel in needsPrep {
            processPostViewModel(postModel)
        }
        
        let toPrep = needsPrep
        let toFetch = relationshipsToFetch
        
        Task {
            let fetchedRelationships = try await feedLoader.fetchRelationships(toFetch)
            
            for postModel in toPrep {
                if postModel.fullPost?.actionablePost?.metaData.author.id == authenticatedUser?.userID {
                    postModel.myRelationshipToAuthor = .isMe
                } else {
                    postModel.myRelationshipToAuthor = fetchedRelationships.first(where: {
                        $0.info?.id == postModel.initialDisplayInfo.actionableAuthorId
                    }) ?? feedLoader.myRelationship(to: postModel.initialDisplayInfo.actionableAuthorId)
                }
                if postModel.actionHandler == nil {
                    postModel.actionHandler = self
                }
                postModel.displayPrepStatus = .donePreparing
            }
            
            for item in batch {
                switch item {
                case .notification(let notificationViewModel):
                    if let relationship = fetchedRelationships.first(where: { $0.info?._legacyEntity.id == notificationViewModel.needsRelationshipTo?.id }) {
                        notificationViewModel.prepareForDisplay(relationship: relationship.info?._legacyEntity, theirAccountIsLocked: notificationViewModel.needsRelationshipTo?.locked ?? false)
                    }
                    notificationViewModel.actionHandler = self
                    notificationViewModel.displayPrepStatus = .donePreparing
                default:
                    break
                }
            }
            
            currentlyPreparingForDisplay = nil
            
            completion?()
        }
    }
}

extension TimelineListViewModel {
    enum LastReadState {
        case initializing
        case untracked
        case requestedReloadFromTop
        case requestedReloadFromBottom
        case pullToRefresh
        
    }
    
    func resetToUntrackedAfterDelay() {
        debugScroll("will reset to untracked")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            // the delay prevents loads immediately triggering new loads
            self.lastReadState = .untracked
            debugScroll("did reset to untracked")
        }
    }
}

extension TimelineListViewModel {
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

struct TimelineListView: View {
    @ObservedObject private var viewModel: TimelineListViewModel
    @State private var scrollManager = ScrollManager()
    
    @ScaledMetric private var avatarSize = AvatarSize.large
    
    fileprivate init(viewModel: TimelineListViewModel) {
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
                            if viewModel.useLazyVStack {
                                LazyVStack {
                                    feedContents(geo)
                                }
                            } else {
                                VStack {
                                    feedContents(geo)
                                }
                            }
                        }
                        .onChange(of: viewModel.currentDisplaySlice, initial: true) { oldValue, newValue in
                            if let threadedModel = viewModel.threadedConversationModel, !threadedModel.hasScrolledToFocusedPost {
                                threadedModel.hasScrolledToFocusedPost = true
                                scrollManager.scrollTo(lastReadID: threadedModel.focusedID, anchor: .top, items: newValue, proxy: proxy) { success in
                                    viewModel.resetToUntrackedAfterDelay()
                                }
                            } else {
                                
                                switch viewModel.lastReadState {
                                case .untracked, .initializing:
                                    debugScroll("NOTHING TO SCROLL TO")
                                    break
                                case .pullToRefresh, .requestedReloadFromTop:
                                    debugScroll("pull to refresh replaced the current slice, doing nothing should jump to the top")
                                    viewModel.resetToUntrackedAfterDelay()
                                case .requestedReloadFromBottom:
                                    debugScroll("reload from bottom replaced the current slice")
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                                        if let topItemID = newValue.first(where: { $0.isRealItem })?.id {
                                            // without requesting scroll, the view seems to automatically peg the loading indicator as the thing that shouldn't move, so you're stuck at the end
                                            debugScroll("scrolling to the top item in the new lower slice")
                                            if let anchorIndex = viewModel.currentDisplaySlice.firstIndex(where: { $0.id == topItemID }) {
                                                debugScroll("will try to scroll to \(topItemID), which is at index \(anchorIndex) in slice \(viewModel.currentDisplaySlice.startIndex)-\(viewModel.currentDisplaySlice.endIndex)")
                                            }
                                            scrollManager.scrollTo(lastReadID: topItemID, anchor: .bottom, items: self.viewModel.currentDisplaySlice, proxy: proxy) { success in
                                                viewModel.resetToUntrackedAfterDelay()
                                            }
                                        } else {
                                            viewModel.resetToUntrackedAfterDelay()
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.scrollToTopRequested, { oldValue, newValue in
                            debugScroll("scroll to top requested")
                            if newValue == true, let anchorID = viewModel.currentDisplaySlice.first?.id { // TODO: jump all the way to the top, or possibly even reload from server
                                Task {
                                    if let anchorIndex = viewModel.currentDisplaySlice.firstIndex(where: { $0.id == anchorID }) {
                                        debugScroll("will try to scroll to \(anchorID), which is at index \(anchorIndex) in slice \(viewModel.currentDisplaySlice.startIndex)-\(viewModel.currentDisplaySlice.endIndex)")
                                    }
                                    scrollManager.scrollTo(lastReadID: anchorID, anchor: .top, items: viewModel.currentDisplaySlice, proxy: proxy, completion: { success in
                                        debugScroll("scroll to top completed! \(success)")
                                        DispatchQueue.main.async {
                                            viewModel.scrollToTopRequested = false
                                        }
                                    })
                                }
                            }
                        })
                        .refreshable {
                            debugScroll("REFRESHABLE?")
                            switch viewModel.lastReadState {
                            case .initializing:
                                break
                            case .untracked:
                                viewModel.lastReadState = .pullToRefresh
                                debugScroll("refreshing feed")
                                await viewModel.refreshFromTop()
                                viewModel.resetToUntrackedAfterDelay()
                            case .pullToRefresh, .requestedReloadFromBottom, .requestedReloadFromTop:
                                debugScroll("not refreshing feed.  current state is \(viewModel.lastReadState)")
                                break
                            }
                        }
                        .accessibilityAction(named: L10n.Common.Controls.Actions.loadNewer) {
                            switch viewModel.lastReadState {
                            case .initializing:
                                break
                            case .untracked:
                                viewModel.lastReadState = .pullToRefresh
                                Task {
                                    await viewModel.refreshFromTop()
                                    viewModel.resetToUntrackedAfterDelay()
                                }
                            case .pullToRefresh, .requestedReloadFromBottom, .requestedReloadFromTop:
                                break
                            }
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
            if viewModel.timeline.canDisplayDonationBanner {
                Task {
                    await viewModel.askForDonationIfPossible()
                }
            }
            if viewModel.timeline.canDisplayUnreadNotifications {
                // clear the notification dot on the tab icon
                NotificationService.shared.clearNotificationCountForActiveUser()
            }
            if viewModel.needsReloadOnNextAppear {
                Task {
                    await viewModel.forceReload(.notificationCountUpdated)
                }
            }
        }
        .onDisappear() {
            viewModel.lastReadState = .untracked
            scrollManager.viewDidDisappear()
        }
        .alert(viewModel.activeAlert.title, isPresented: $viewModel.isPresentingAlert, presenting: viewModel.activeAlert) { alert in
            alertContents(alert)
        } message: { alert in
            if let messageText = alert.messageText {
                Text(messageText)
            }
        }
        .sheet(isPresented: $viewModel.isShowingSheet) {
            switch viewModel.activeSheet {
            case .postInteractionSettingsEdit(let editModel):
                PostInteractionSettingsView(closeAndSave: { save in
                    if save {
                        Task {
                            do {
                                try await viewModel.commitCurrentQuotePolicyEdit()
                                viewModel.clearPendingActions()
                            } catch {
                                viewModel.clearPendingActions()
                                self.viewModel.didReceiveError(error)
                            }
                        }
                    } else {
                        viewModel.clearPendingActions()
                    }
                })
                .environment(editModel)
                .presentationDetents([.fraction(0.3), .medium, .large])
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
            case .boostOrQuoteDialog(let postViewModel):
                BoostOrQuoteDialog()
                    .environment(postViewModel)
                    .presentationDetents([.fraction(0.3), .medium, .large])
            case .none:
                EmptyView()
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
                            
                            activeOverlay.view(sizedForFrame: geo.size, closeOverlay: { viewModel.showOverlay(nil) })
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
        .environment(TimestampUpdater.timestamper(withInterval: 30))
    }
    
    @ViewBuilder func feedContents(_ geo: GeometryProxy) -> some View {
        let usableWidth = geo.size.width - geo.safeAreaInsets.leading - geo.safeAreaInsets.trailing
        let contentWidth = max(1, usableWidth - (standardPadding /*left margin*/ + spacingBetweenGutterAndContent /*avatar trailing to content leading*/ + doublePadding /*right margin*/) - avatarSize)
        ForEach(viewModel.currentDisplaySlice, id: \.self) { item in
            switch item {
            case .loadingIndicator:
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                    Spacer()
                }
                .padding(EdgeInsets(top: 100, leading: 0, bottom: 100, trailing: 0))
                .accessibilityAction(named: L10n.Common.Controls.Actions.loadOlder) {
                    switch viewModel.lastReadState {
                    case .untracked:
                        viewModel.loadMoreFromBottom()
                    default:
                        break
                    }
                }
                VisibilityTrackingView(visibilityDidChange: { isVisible in
                    if isVisible {
                        switch viewModel.lastReadState {
                        case .initializing:
                            viewModel.resetToUntrackedAfterDelay()
                        case .untracked:
                            viewModel.loadMoreFromBottom()
                        default:
                            break
                        }
                    }
                },
                                       scrollCoordinateSpace: scrollViewCoordinateSpace,
                                       visibleAreaHeight: geo.size.height)
                .frame(width: 10, height: 1)
                
            case .filteredNotificationsInfo(_, let filteredNotificationsViewModel):
                if let filteredNotificationsViewModel {
                    FilteredNotificationsRowView(contentWidth: contentWidth)
                        .environment(filteredNotificationsViewModel)
                        .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: usableWidth)
                        .accessibilityElement(children: .combine)
                        .accessibilityAction {
                            goToFilteredNotifications(filteredNotificationsViewModel)
                        }
                        .onTapGesture {
                            goToFilteredNotifications(filteredNotificationsViewModel)
                        }
                } else {
                    Text("Some notifications have been filtered.")
                        .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: usableWidth)
                }
                Divider()
                
            case .post(let postViewModel):
#if DEBUG && false
                Text(postViewModel.initialDisplayInfo.id)
                    .foregroundStyle(.red)
                    .fontWeight(.bold)
                if let actionablePostID = postViewModel.fullPost?.actionablePost?.id, actionablePostID != postViewModel.initialDisplayInfo.id {
                    Text("actionable: \(actionablePostID)")
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
#endif
                
                MastodonPostRowView(contentWidth: contentWidth)
                .environment(postViewModel)
                .environment(viewModel.contentConcealModel(forActionablePost: postViewModel.initialDisplayInfo.actionablePostID))
                .padding(EdgeInsets(top: 0, leading: standardPadding, bottom: 0, trailing: doublePadding))
                .frame(width: usableWidth)
                .background() {
                    switch viewModel.timeline {
                    case .notifications:
                        switch postViewModel.initialDisplayInfo.actionableVisibility {
                        case .mentionedOnly:
                            backgroundView(isPrivate: true, isUnread: false) // TODO: implement unread for notifications
                        default:
                            EmptyView()
                        }
                    default:
                        EmptyView()
                    }
                }
            case .notification(let notificationViewModel):
                NotificationRowView(contentWidth: contentWidth)
                    .environment(notificationViewModel)
                    .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                    .frame(width: usableWidth)
                    .background() {
                        if let inlinePost = notificationViewModel.inlinePostViewModel {
                            switch inlinePost.initialDisplayInfo.actionableVisibility {
                            case .mentionedOnly:
                                backgroundView(isPrivate: true, isUnread: false) // TODO: implement unread for notifications
                            default:
                                EmptyView()
                            }
                        }
                    }
            }
        }
        if viewModel.threadedConversationModel != nil {
            // include a spacer to indicate the end of the conversation and provide scrolling space so that if the focused post is at the end of the conversation it can still be scrolled to the top (or something near it)
            Color.clear
                .frame(height: geo.size.height * 0.5)
        }
        switch viewModel.timeline {
        case .userPosts:
            // include a spacer to allow content to scroll above the tab bar while we are still using the old ProfileViewController (which lays out these view controllers so that they hang mostly off the bottom of the screen, to allow the overall view to scroll up and show these views at full screen height)
            let spacerHeightHackToMakeScrollingWorkUntilWeReplaceProfileViewController: CGFloat = {
                let frame = geo.frame(in: .global)
                let screenHeight = UIScreen.main.bounds.height
                let offscreenBottom = max(frame.maxY - screenHeight, 0)
                return offscreenBottom + geo.safeAreaInsets.bottom
            }()
            Spacer()
                .frame(width: 200, height: spacerHeightHackToMakeScrollingWorkUntilWeReplaceProfileViewController)  // TODO: remove when replacing ProfileViewController
        default:
            EmptyView()
        }
    }
    
    func goToFilteredNotifications(_ viewModel: FilteredNotificationsRowView.ViewModel) {
        viewModel.isPreparingToNavigate = true
        Task {
            await navigateToFilteredNotifications()
            viewModel.isPreparingToNavigate = false
        }
    }
    
    private func navigateToFilteredNotifications() async {
        guard
            let authBox = AuthenticationServiceProvider.shared.currentActiveUser
                .value
        else { return }

        do {
            let notificationRequests = try await APIService.shared
                .notificationRequests(authenticationBox: authBox).value
            let requestsViewModel = NotificationRequestsViewModel(
                authenticationBox: authBox, requests: notificationRequests)

            viewModel.presentScene(
                .notificationRequests(viewModel: requestsViewModel), fromPost: nil, transition: .show)  // TODO: should be .modal(animated) on large screens?
        } catch {
            viewModel.didReceiveError(error)
        }
    }
    
    @ViewBuilder func backgroundView(isPrivate: Bool, isUnread: Bool) -> some View {
        HStack(spacing: 0) {
            if isUnread && UserDefaults.standard.testUnreadMarkersForNotifications {
                Rectangle()
                    .fill(Asset.Colors.accent.swiftUIColor)
                    .frame(width: 8)
            }
            Rectangle()
                .fill(isPrivate ?  Asset.Colors.accent.swiftUIColor : .clear)
                .padding(EdgeInsets(top: 1, leading: 0, bottom: 1, trailing: 0))
                .opacity(0.1)
        }
    }
    
    @ViewBuilder func alertContents(_ alert: MastodonPostMenuAction.AlertType) -> some View {
        switch alert {
        case .noAlert:
            Text("no alert")
        case .confirmBoostOfPost(let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Alerts.BoostAPost.boost)
            }
            
            
        case .confirmRemoveQuote(_, let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Actions.remove)
            }
            
        case .confirmDeleteOfPost(let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Actions.delete)
            }
            
        case .confirmUnfollow(_, let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Alerts.UnfollowUser.unfollow)
            }
            
        case .confirmMute(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.muteUser(username))
            }
        case .confirmUnmute(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.unmuteUser(username))
            }
            
        case .confirmBlock(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button(role: .destructive) {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.blockUser(username))
            }
        case .confirmUnblock(username: let username, didConfirm: let didConfirm):
            cancelButton(didConfirm)
            Button {
                didConfirm(true)
            } label: {
                Text(L10n.Common.Controls.Friendship.unblockUser(username))
            }
        case .error(let error):
            Button(L10n.Common.Controls.Actions.ok) {
            }
        }
    }
    
    @ViewBuilder func cancelButton(_ didConfirm: @escaping (Bool)->()) -> some View {
        Button(role: .cancel) {
            viewModel.clearPendingActions()
            didConfirm(false)
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

    func scrollTo(lastReadID: String?, anchor: UnitPoint?, items: ArraySlice<TimelineItem>, proxy: ScrollViewProxy, retryCount: Int = totalRetryCount, completion: @escaping (Bool)->()) {
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
            proxy.scrollTo(anchorItem, anchor: anchor)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100 * (totalRetryCount - retryCount))) { [weak self] in
                guard let self, retryCount > 0 else {
                    debugScroll("failed all retries!")
                    completion(false)
                    return
                }
                if let lastReadID, !self.visibleItems.contains(lastReadID) {
                    scrollTo(lastReadID: lastReadID, anchor: anchor, items: items, proxy: proxy, retryCount: retryCount - 1, completion: completion)
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
    @MainActor
    @ViewBuilder func view(sizedForFrame frameSize: CGSize, closeOverlay: @escaping ()->()) -> some View {
        switch self {
        case .altText(let altTextString):
            AltTextView(altTextString: altTextString, frameSize: frameSize)
        case .images(let focusedImage, let viewModel):
            if let img = viewModel.imageAttachments.first(where: { $0.id == focusedImage }) {
                ZoomableBlurhashImageView(image: img, frameSize: frameSize)
            }
        }
    }
}

extension TimelineListViewModel: MastodonPostMenuActionHandler {
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
    
    func showSheet(_ sheet: MastodonTimelineSheet?) {
        activeSheet = sheet
    }
    
    func presentScene(_ scene: SceneCoordinator.Scene, fromPost postID: Mastodon.Entity.Status.ID?, transition: SceneCoordinator.Transition) {
        if activeSheet != nil {
            activeSheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(400)) { // without this delay, the presentation gets tangled up with the dismissing sheet
                self.parentVcPresentScene?(scene, transition)
            }
        } else {
            self.parentVcPresentScene?(scene, transition)
        }
    }
    
    func account(_ id: Mastodon.Entity.Account.ID) -> MastodonAccount? {
        return feedLoader?.account(id)
    }
    
    func currentRelationship(to account: Mastodon.Entity.Account.ID) -> MastodonAccount.Relationship? {
        return feedLoader?.myRelationship(to: account)
    }
    
    func doAction(_ action: MastodonPostMenuAction, forPost postViewModel: MastodonPostViewModel) {
        
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
                        let canDoQuotePosts = AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.quotePosts) ?? false
                        await boost(actionablePost.id, askFirst: !canDoQuotePosts && UserDefaults.standard.askBeforeBoostingAPost)
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
                            case .loadingIndicator, .filteredNotificationsInfo:
                                break
                            case .post(let viewModel):
                                viewModel.isShowingTranslation = true
                            case .notification:
                                break
                            }
                        }
                    })
                case .showOriginalLanguage:
                    feedLoader?.updateCachedResults({ timeline in
                        for item in timeline.items {
                            switch item {
                            case .loadingIndicator, .filteredNotificationsInfo:
                                break
                            case .post(let viewModel):
                                viewModel.isShowingTranslation = false
                            case .notification:
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
                        composeContext: .editStatus(status: MastodonStatus(entity: statusEntityToEdit, showDespiteContentWarning: true), statusSource: statusSourceToEdit, quoting: {
                            if let quotedPostViewModel = postViewModel.fullQuotedPostViewModel {
                                AnyView(
                                    EmbeddedPostView(layoutWidth: 200, isSummary: false)
                                        .environment(quotedPostViewModel)
                                        .environment(TimestampUpdater.timestamper(withInterval: 30))
                                        .environment(ContentConcealViewModel.alwaysShow)
                                    
                                )
                            } else {
                                AnyView(EmptyView())
                            }
                        }),
                        destination: .topLevel, completion: { success in
                            // refetch the post to display the edits
                            if success {
                                self.refetchAndDisplay(actionablePostID: statusEntityToEdit.id)
                            }
                        })
                    presentScene(.editStatus(viewModel: editStatusViewModel), fromPost: nil, transition: .modal(animated: true))
                    
                case .changeQuotePolicy:
                    activeSheet = .postInteractionSettingsEdit(
                        PostInteractionSettingsViewModel(
                            account: actionablePost.metaData.author._legacyEntity,
                            initialSettings:
                                    .editing(
                                        visibility: actionablePost._legacyEntity.visibility ?? .public,
                                        quotability: actionablePost._legacyEntity.specifiedQuotePolicyOrNobody
                                    )
                        )
                    )
                    
            // MARK: POST ACTIONS
                case .copyLinkToPost:
                    guard let urlString = actionablePost.metaData.url else { throw PostActionFailure.noActionablePostId }
                    UIPasteboard.general.string = urlString
                    
                case .openPostInBrowser:
                    guard let urlString = actionablePost.metaData.url, let url = URL(string: urlString) else { throw PostActionFailure.noActionablePostId }
                    presentScene(.safari(url: url), fromPost: nil, transition: .safariPresent(animated: true))
                    
                case .sharePost:
                    sharePost(actionablePost)

            // MARK: RELATIONSHIP ACTIONS
                    
                case .follow, .unfollow, .mute, .unmute:
                    try await doAction(action, forAccount: author)
                    
            // MARK: DEFENSIVE ACTIONS
                case .removeQuote:
                    try await doRemoveQuote(from: actionablePost, askFirst: true)
                case .blockUser:
                    activeAlert = .confirmBlock(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                        guard confirmed else { return }
                        Task {
                            await self?.commitBlock(author.id)
                        }
                    })
                    
                case .unblockUser:
                    activeAlert = .confirmUnblock(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                        guard confirmed else { return }
                        Task {
                            await self?.commitUnblock(author.id)
                        }
                    })
                    
                case .reportUser:
                    guard let relationship = try await APIService.shared.relationship(forAccountIds: [author.id], authenticationBox: authenticatedUser).value.first else { throw PostActionFailure.noRelationshipInfo }
                    let accountToReport = try await APIService.shared.accountInfo(domain: authenticatedUser.domain, userID: author.id, authorization: authenticatedUser.userAuthorization)
                    
                    let statusEntity: Mastodon.Entity.Status?
                    statusEntity = try? await APIService.shared.status(statusID: actionablePost.id, authenticationBox: authenticatedUser).value
                    
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
                    await deletePost(actionablePost.id, askFirst: UserDefaults.shared.askBeforeDeletingAPost)
                }
            } catch {
                didReceiveError(error)
                assertionFailure()
                clearPendingActions()
            }
        }
    }
    
    func commitCurrentQuotePolicyEdit() async throws {
        guard let (action, post) = isPerformingPostAction, action == .changeQuotePolicy, let authBox = AuthenticationServiceProvider.shared.currentActiveUser
            .value, case let .postInteractionSettingsEdit(editModel) = activeSheet else { throw PostActionFailure.unsupportedAction }
        Task {
            do {
                let updated = try await APIService.shared.updateQuotePolicy(forStatus: post.id, to: editModel.interactionSettings.quotability, authenticationBox: authBox)
                feedLoader?.updatePost(post: GenericMastodonPost.fromStatus(updated))
            } catch {
                didReceiveError(error)
            }
        }
    }
    
    func doRemoveQuote(from quotingPost: MastodonContentPost, askFirst: Bool) async throws {
        if askFirst {
            activeAlert = .confirmRemoveQuote(username: quotingPost.initialDisplayInfo(inContext: nil).actionableAuthorDisplayName, didConfirm: { confirmed in
                guard confirmed else { return }
                Task {
                    await self.commitRemoveQuote(from: quotingPost)
                }
            })
        } else {
            await commitRemoveQuote(from: quotingPost)
        }
    }
    
    func doAction(_ action: MastodonPostMenuAction, forAccount account: MastodonAccount) async throws {
        let currentRelationship =  myRelationship(to: account).info
        switch action {
        case .follow:
            guard currentRelationship?.canFollow == true else { throw PostActionFailure.noRelationshipInfo }
            await commitFollow(account.id)
        case .unfollow:
            await doUnfollow(account, askFirst: UserDefaults.standard.askBeforeUnfollowingSomeone)
        case .mute:
            await doMute(account, askFirst: true)
        case .unmute:
            await doUnmute(account, askFirst: true)
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
                activeAlert = .confirmBoostOfPost(didConfirm: { [weak self] confirmed in
                    guard confirmed else { return }
                    Task {
                        await self?.boost(actionablePostId, askFirst: false)
                    }
                })
            } else {
                let updated = try await APIService.shared.boost(boostableStatusId: actionablePostId, authenticationBox: authenticatedUser) // this returns a new post, which is the boost action
                let updatedActionable = updated.reblog ?? updated // when updating the existing records, we only care about the original post
                feedLoader?.updatePost(post: GenericMastodonPost.fromStatus(updatedActionable))
                clearPendingActions()
            }
        } catch {
            didReceiveError(error)
            clearPendingActions()
        }
    }
    
    // RELATIONSHIP ACTIONS
    
    func doUnfollow(_ author: MastodonAccount, askFirst: Bool) async {
        do {
            if askFirst {
                await withCheckedContinuation { continuation in
                    activeAlert = .confirmUnfollow(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                        guard confirmed else { continuation.resume(); return }
                        Task {
                            await self?.doUnfollow(author, askFirst: false)
                            continuation.resume()
                        }
                    })
                }
            } else {
                guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
                let response = try await APIService.shared.unfollow(author.id, authenticationBox: authenticatedUser)
                let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
                feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: author.id)
                AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
            }
        } catch {
            didReceiveError(error)
            assert(false)
        }
        isPerformingAccountAction = nil
    }
    
    func doMute(_ author: MastodonAccount, askFirst: Bool) async {
        if askFirst {
            await withCheckedContinuation { continuation in
                self.activeAlert = .confirmMute(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                    guard confirmed else { continuation.resume(); return }
                    Task {
                        await self?.commitMute(author.id)
                        continuation.resume()
                    }
                })
            }
        } else {
            await commitMute(author.id)
        }
    }
    
    func doUnmute(_ author: MastodonAccount, askFirst: Bool) async {
        if askFirst {
            await withCheckedContinuation { continuation in
                self.activeAlert = .confirmUnmute(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                    guard confirmed else { continuation.resume(); return }
                    Task {
                        await self?.commitUnmute(author.id)
                        continuation.resume()
                    }
                })
            }
        } else {
            await commitUnmute(author.id)
        }
    }
    
    func commitFollow(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.follow(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: accountID)
            AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
        } catch {
            didReceiveError(error)
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
            didReceiveError(error)
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
            didReceiveError(error)
        }
        isPerformingAccountAction = nil
    }
     
    // DEFENSIVE ACTIONS
    
    func commitRemoveQuote(from quotingPost: MastodonContentPost) async {
        do {
            guard let actionablePost = quotingPost.actionablePost as? MastodonBasicPost, let quoted = actionablePost.quotedPost, let quotedId = quoted.fullPost?.id, let authenticatedUser else { throw PostActionFailure.noActionablePostId }
            let updated = try await APIService.shared.revokeQuoteAuthorization(forQuotedId: quotedId, fromQuotingId: actionablePost.id, authenticationBox: authenticatedUser)
            feedLoader?.updatePost(post: GenericMastodonPost.fromStatus(updated))
            clearPendingActions()
        } catch {
            didReceiveError(error)
            clearPendingActions()
        }
    }
    
    func commitBlock(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.block(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            feedLoader?.updateMyRelationship(.isNotMe(newRelationshipInfo), to: accountID)
            AuthenticationServiceProvider.shared.sendDidChangeFollowersAndFollowing(for: authenticatedUser.globallyUniqueUserIdentifier)
        } catch {
            didReceiveError(error)
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
            didReceiveError(error)
        }
        isPerformingAccountAction = nil
    }
    
    func deletePost(_ postID: Mastodon.Entity.Status.ID, askFirst: Bool) async {
        do {
            if askFirst {
                activeAlert = .confirmDeleteOfPost(didConfirm: { [weak self] confirmed in
                    guard confirmed else { return }
                    Task {
                        await self?.deletePost(postID, askFirst: false)
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
            didReceiveError(error)
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
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(translatedFromLanguageByProvider + ", " + L10n.Common.Controls.Status.Translation.showOriginal)
        .accessibilityAction {
            showOriginal()
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
