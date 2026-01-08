// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK
import MastoParse
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
    case discover(DiscoveryType)
    case myBookmarks
    case myFavorites
    case myFollowedHashtags
    case followers(ofUserId: Mastodon.Entity.Account.ID)
    case accountsFollowed(byUserId: Mastodon.Entity.Account.ID)
    case search(String, scope: SearchScope)
    case profilePosts(tabTitle: String?, userID: String, queryFilter: TimelineQueryFilter)
    case thread(root: MastodonContentPost)
    case remoteThread(root: RemoteThreadType)
    case hashtag(Mastodon.Entity.Tag)
    case whoFavourited(actionableStatusID: Mastodon.Entity.Status.ID)
    case whoBoosted(actionableStatusID: Mastodon.Entity.Status.ID)
    
    var tabTitle: String? {
        switch self {
        case .profilePosts(let tabTitle, _, _):
            return tabTitle
        default:
            return nil
        }
    }
}

class TimelineListViewController: UIHostingController<AnyView>
{
    public let type: TimelineViewType
    private let viewModel: TimelineListViewModel
    private let asyncRefreshViewModel = AsyncRefreshViewModel()
    private let nestedScrollViewModel = NestedScrollInteractionViewModel()
    private var navigationFlow: NavigationFlow?
    private let _mediaPreviewTransitionController = MediaPreviewTransitionController()
    
    init(_ type: TimelineViewType) {
        self.type = type
        switch type {
        case .home:
            viewModel = TimelineListViewModel(timeline: .homeTimeline, asyncRefreshViewModel: asyncRefreshViewModel)
        case .notifications(let scope):
            viewModel = TimelineListViewModel(timeline: .notifications(scope: scope), asyncRefreshViewModel: asyncRefreshViewModel)
        case .discover(let type):
            viewModel = TimelineListViewModel(timeline: .discover(type), asyncRefreshViewModel: asyncRefreshViewModel)
        case .search(let searchText, let scope):
            viewModel = TimelineListViewModel(timeline: .search(searchText, scope), asyncRefreshViewModel: asyncRefreshViewModel)
        case .profilePosts(_, let user, let queryFilter):
            viewModel = TimelineListViewModel(timeline: .userPosts(userID: user, queryFilter: queryFilter), asyncRefreshViewModel: asyncRefreshViewModel)
        case .thread(let root):
            viewModel = TimelineListViewModel(timeline: .thread(root: root), asyncRefreshViewModel: asyncRefreshViewModel)
        case .remoteThread(let remoteThreadType):
            viewModel = TimelineListViewModel(timeline: .remoteThread(remoteType: remoteThreadType), asyncRefreshViewModel: asyncRefreshViewModel)
        case .followers(let followedAccount):
            viewModel = TimelineListViewModel(timeline: .followers(ofUserId: followedAccount), asyncRefreshViewModel: asyncRefreshViewModel)
        case .accountsFollowed(let followingAccount):
            viewModel = TimelineListViewModel(timeline: .accountsFollowed(byUserId: followingAccount), asyncRefreshViewModel: asyncRefreshViewModel)
        case .myFollowedHashtags:
            viewModel = TimelineListViewModel(timeline: .myFollowedHashtags, asyncRefreshViewModel: asyncRefreshViewModel)
        case .myBookmarks:
            viewModel = TimelineListViewModel(timeline: .myBookmarks, asyncRefreshViewModel: asyncRefreshViewModel)
        case .myFavorites:
            viewModel = TimelineListViewModel(timeline: .myFavorites, asyncRefreshViewModel: asyncRefreshViewModel)
        case .hashtag(let tag):
            viewModel = TimelineListViewModel(timeline: .hashtag(tag, includeHeader: true), asyncRefreshViewModel: asyncRefreshViewModel)
        case .whoFavourited(let statusID):
            viewModel = TimelineListViewModel(timeline: .whoFavourited(actionableStatusID: statusID), asyncRefreshViewModel: asyncRefreshViewModel)
        case .whoBoosted(let statusID):
            viewModel = TimelineListViewModel(timeline: .whoBoosted(actionableStatusID: statusID), asyncRefreshViewModel: asyncRefreshViewModel)
        }
        let root = TimelineListView().environment(viewModel).environment(viewModel.timeline.filterModel).environment(asyncRefreshViewModel).environment(nestedScrollViewModel)
        super.init(rootView: AnyView(root))
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
        
        setUpNavigationBar()
    }
    
    func setUpNavigationBar() {
        switch type {
        case .home:
            setUpTimelineSelectorButton()
            self.navigationItem.rightBarButtonItem = settingBarButtonItem
        case .notifications:
            setUpNotificationsNavBarControls()
            if viewModel.timeline.canDisplayFilteredNotifications {
                NotificationCenter.default.addObserver(self, selector: #selector(notificationFilteringPolicyDidChange), name: .notificationFilteringChanged, object: nil)
            }
        case .thread(let focusedPost):
            let authorHandle = focusedPost.initialDisplayInfo().actionableAuthorHandle
            navigationItem.title = L10n.Scene.Thread.title("@\(authorHandle)")
            
        case .discover, .myBookmarks, .myFavorites, .profilePosts, .remoteThread:
            break
            
        case .whoFavourited:
            navigationItem.title = L10n.Scene.FavoritedBy.title
            
        case .whoBoosted:
            navigationItem.title = L10n.Scene.RebloggedBy.title
            
        case .followers:
            navigationItem.title = L10n.Scene.Follower.title
        case .accountsFollowed:
            navigationItem.title = L10n.Scene.Following.title
            
        case .search(let string, _):
            navigationItem.title = string
        case .hashtag(let tag):
            navigationItem.title = "#\(tag.name)"
            navigationItem.rightBarButtonItem = composeHashtagButtonItem
        case .myFollowedHashtags:
            navigationItem.title = L10n.Scene.FollowedTags.title
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
    
    lazy var composeHashtagButtonItem: UIBarButtonItem = {
        let barButtonItem = UIBarButtonItem()
        barButtonItem.tintColor = Asset.Colors.Brand.blurple.color
        barButtonItem.image = UIImage(systemName: "square.and.pencil")
        barButtonItem.accessibilityLabel = L10n.Common.Controls.Actions.compose
        barButtonItem.target = self
        barButtonItem.action = #selector(Self.composeHashtagBarButtonItemPressed(_:))
        return barButtonItem
    }()
    
    lazy var picker = { UISegmentedControl(items: [ NotificationsScope.everything.pickerLabel, NotificationsScope.mentions.pickerLabel ]) }()
    
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
    @objc func scrollToTop() {
        viewModel.scrollToTop()
    }
    
    @objc private func settingBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let setting = SettingService.shared.currentSetting.value else { return }
        
        _ = self.sceneCoordinator?.present(scene: .settings(setting: setting), from: self, transition: .none)
    }
    
    @objc private func composeHashtagBarButtonItemPressed(_ sender: UIBarButtonItem) {
        guard let authenticatedUser = viewModel.authenticatedUser else { return }
        switch viewModel.timeline {
        case .hashtag(let tag, _):
            let composeViewModel = ComposeViewModel(
                authenticationBox: authenticatedUser,
                composeContext: .composeStatus(quoting: nil),
                destination: .topLevel,
                initialContent: "#\(tag.name)",
                completion: { success in
                   // TODO: reload at least enough to indicate that there is an additional post
                }
            )
            viewModel.presentScene(.compose(viewModel: composeViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
        default:
            break
        }
    }
    
    func setUpTimelineSelectorButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: timelineSelectorButton)
        if #available(iOS 26.0, *) {
            self.navigationItem.leftBarButtonItem?.hidesSharedBackground = true
        }
    }
    
    @MainActor
    private func generateTimelineSelectorMenu() -> UIMenu {
        let showFollowingAction = UIAction(title: L10n.Scene.HomeTimeline.TimelineMenu.following, image: .init(systemName: "house")) { [weak self] _ in
            guard let self else { return }
            
            viewModel.timeline = .homeTimeline
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
        case .homeTimeline:
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
        case .discover, .search, .userPosts, .thread, .remoteThread, .myFollowedHashtags, .myBookmarks, .myFavorites, .notifications, .followers, .accountsFollowed, .whoFavourited, .whoBoosted:
            assertionFailure()
            break
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
                
                var listEntries = lists.sorted(by: { first, second in
                    return first.title < second.title
                }).map { entry in
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
                        viewModel.timeline = .hashtag(entry, includeHeader: false)
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
        
        // check if the instance allows the local timeline
        if AuthenticationServiceProvider.shared.currentActiveUser.value?.authentication.instanceConfiguration?.isAvailable(.localTimeline) ?? true {
            return UIMenu(children: [showFollowingAction, showLocalTimelineAction, listsDivider])
        } else {
            guard listsMenu.children.count > 0 || hashtagsMenu.children.count > 0 else { return UIMenu(children: [showFollowingAction]) }
            return UIMenu(children: [showFollowingAction, listsDivider])
        }
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
                viewModel.resetToUntrackedAfterDelay(from: viewModel.loadingState)
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
@Observable class TimelineListViewModel {
    
    private(set) var authenticatedUser: MastodonAuthenticationBox? = AuthenticationServiceProvider.shared.currentActiveUser.value
    
    var unreadCount: Int = 0
    private(set) var waitingReplacementItems: [TimelineItem]?
    
    var presentedDonationCampaign: Mastodon.Entity.DonationCampaign?
    
    var isPresentingActivityFilter: Bool = false
    
    var isPerformingPostAction: (action: MastodonPostMenuAction, post: MastodonContentPost)? = nil
    var isPerformingAccountAction: (action: MastodonPostMenuAction, account: MastodonAccount)? = nil
    
    var feedIsEmpty: Bool = false
    
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
        if unreadCount > 0 {
            if let indexOfNewScrollAnchor = currentDisplaySlice.firstIndex(of: scrollAnchor), indexOfNewScrollAnchor < unreadCount {
                unreadCount = indexOfNewScrollAnchor
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
    }
    
    public var parentVcPresentScene: ((SceneCoordinator.Scene, SceneCoordinator.Transition) -> ())?
    public var presentDonationDialog: ((Mastodon.Entity.DonationCampaign) -> ())?
    
    private var instanceConfigurationUpdateSubscription: AnyCancellable?

    var hostingViewController: MediaPreviewableViewController?
    
    var filteredNotificationsViewModel =
        FilteredNotificationsRowView.ViewModel(policy: nil)
    var needsReloadOnNextAppear = false
    
    // MARK - Alerts
    var errorsWaitingToDisplay = [Error]()
    var activeAlert: MastodonPostMenuAction.AlertType = .noAlert {
        didSet {
            displayNextErrorIfPossible()
        }
    }
    var alertIsPresented: Binding<Bool> {
        Binding(get: { [weak self] in
            return self?.activeAlert.shouldBePresented ?? false
        }, set: { [weak self] isPresenting in
            if !isPresenting {
                self?.activeAlert = .noAlert
            }
        })
    }
    
    // MARK - Overlays
    var activeOverlay: MastodonTimelineOverlayView? = nil
    @ViewBuilder func overlayContents(_ overlay: MastodonTimelineOverlayView) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                ZStack {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .onTapGesture { [weak self] in
                            self?.activeOverlay = nil
                        }
                    
                    overlay.view(sizedForFrame: geo.size, closeOverlay: { self.showOverlay(nil) })
                }
                
                Button {
                    self.activeOverlay = nil
                } label: {
                    Image(systemName: "xmark.circle")
                        .font(.title)
                        .foregroundStyle(.white)
                }
                .padding(standardPadding)
            }
        }
    }
    
    // MARK - Sheets
    var activeSheet: MastodonTimelineSheet? = nil
    var sheetIsPresented: Binding<Bool> {
        Binding(get: { [weak self] in
            self?.activeSheet != nil
        }, set: { [weak self] isPresented in
            if !isPresented {
                self?.activeSheet = nil
            }
        })
    }
    @ViewBuilder var activeSheetContents: some View {
        switch activeSheet {
        case .postInteractionSettingsEdit(let editModel):
            PostInteractionSettingsView(closeAndSave: { [weak self] save in
                if save {
                    Task {
                        do {
                            try await self?.commitCurrentQuotePolicyEdit()
                            self?.clearPendingActions()
                        } catch {
                            self?.clearPendingActions()
                            self?.didReceiveError(error)
                        }
                    }
                } else {
                    self?.clearPendingActions()
                }
            })
            .environment(editModel)
            .presentationDetents([.fraction(0.5), .medium, .large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        case .boostOrQuoteDialog(let postViewModel):
            BoostOrQuoteDialog(actionHandler: self)
                .environment(postViewModel)
                .presentationDetents([.fraction(0.3), .medium, .large])
        case .none:
            EmptyView()
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
            case .notification, .hashtag, .account, .filteredNotificationsInfo, .loadingIndicator, .noItem:
                currentDisplaySlice = prefix + newSlice + suffix
                self.resetToUntrackedAfterDelay(from: loadingState)
            }
        } else {
            currentDisplaySlice = prefix + newSlice + suffix
            self.resetToUntrackedAfterDelay(from: loadingState)
        }
    }
    
    private var followersAndBlockedChangeSubscription: AnyCancellable?
    private var feedLoader: TimelineFeedLoader?
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
            loadingState = .untracked
            currentDisplaySlice = ArraySlice([.loadingIndicator])
            Task {
                try await doInitialLoad()
            }
        }
    }
    
    private let _asyncRefreshViewModel: AsyncRefreshViewModel?
    
    init(timeline: MastodonTimelineType, asyncRefreshViewModel: AsyncRefreshViewModel?) {
        self.timeline = timeline
        self._asyncRefreshViewModel = asyncRefreshViewModel
        
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
    
    private var hasFetchedFeaturedHashtags: Bool = false
    func fetchFeaturedHashtags() async -> [Mastodon.Entity.FeaturedTag]? {
        guard !hasFetchedFeaturedHashtags else { return nil }
        guard let authBox = self.authenticatedUser else { return nil }
        hasFetchedFeaturedHashtags = true
        do {
            return try await APIService.shared.featuredTags(forAccount: self.timeline.accountID, authenticationBox: authBox).value
        } catch {
            hasFetchedFeaturedHashtags = false
            return nil
        }
    }
    
    func setUpFeedLoaderResultsSubscription() {
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
                    case .loadingIndicator, .filteredNotificationsInfo, .hashtag, .noItem:
                        return nil
                    case .account:
                        return item
                    case .post(let postViewModel):
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
            
            safeToSetNewItemsImmediately = {
                if self.scrollAnchorItem == .noItem || currentFeedIsEmpty {
                    return true
                } else if items.firstIndex(of: self.scrollAnchorItem) == nil {
                    return false
                } else {
                    return true
                }
            }()
            
            newScrollAnchor = nil // leave the scrollAnchor alone
            
            if self.scrollAnchorItem == .noItem || currentFeedIsEmpty {
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
            newItemsCount = self.unreadCount
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
            self.unreadCount = newItemsCount
        }
        
        if safeToSetNewItemsImmediately {
            self.resetToUntrackedAfterDelay(from: loadingState)
            self.setCurrentDisplaySlice(items.prefix(items.count), newScrollAnchor: initialThreadAnchorItem ?? newScrollAnchor, mayNeedHeightCalculations: true, addLoadingIndicator: canLoadOlder)
        } else {
            self.waitingReplacementItems = items
        }
    }
    
    func doInitialLoad() async throws {
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
        
        clearPendingActions()
        feedLoader = TimelineFeedLoader(currentUser: authenticatedUser, timeline: timeline, asyncRefreshViewModel: _asyncRefreshViewModel)
        
        setUpFeedLoaderResultsSubscription()
        
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
    
    func forceReload(_ reason: ReloadReason) async {
        guard let feedLoader else {
            resetToUntrackedAfterDelay(from: loadingState)
            assertionFailure()
            return
        }
        needsReloadOnNextAppear = false
        switch reason {
        case .notificationCountUpdated:
            fetchFilteredNotificationsPolicy(andReloadFeed: true)
        case .notificationFilterPolicyUpdated:
            loadingState = .requestedReloadFromTop
            feedLoader.requestLoad(.reload)
        case .activityFilterUpdated:
            loadingState = .initializing
            interactiveReloadTriggerModel.reset(triggered: true)
            feedLoader.requestLoad(.reloadForFilterChange)
        case .asyncRefreshResultsRequested:
            loadingState = .requestedAsyncRefreshResults
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
    
    func suggestAccountsToFollow() {
        guard let authenticatedUser else { return }
        let suggestionAccountViewModel = SuggestionAccountViewModel(authenticationBox: authenticatedUser)
        presentScene(.suggestionAccount(viewModel: suggestionAccountViewModel), fromPost: nil, transition: .modal(animated: true, completion: nil))
    }
}

extension TimelineListViewModel {
    var timelineQueryFilter: TimelineQueryFilter? {
        switch timeline {
        case .userPosts(_, let queryFilter):
            queryFilter
        default:
            nil
        }
    }
    
    var includeBoosts: Bool {
        get {
            !(timelineQueryFilter?.excludeReblogs ?? false)
        }
        set {
            timelineQueryFilter?.excludeReblogs = !newValue
            Task {
                await forceReload(.activityFilterUpdated)
            }
        }
    }
    
    var includeReplies: Bool {
        get {
            !(timelineQueryFilter?.excludeReplies ?? true)
        }
        set {
            timelineQueryFilter?.excludeReplies = !newValue
            Task {
                await forceReload(.activityFilterUpdated)
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
            case .post(let viewModel):
                return viewModel
            default:
                assertionFailure("precalculating height is not supported for \(item.id)")
                return nil
            }
        })
        Task {
            for model in toCalculate {
                await calculateHeight(model)
            }
            let calculatedItems = toCalculate.map { model in
                TimelineItem.post(model)
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
    
    func calculateHeight(_ model: MastodonPostViewModel) async {
        guard let currentUseableWidth else { return }
        let contentWidth = contentWidth(forUseableWidth: currentUseableWidth)
        let height = await ViewMeasurer.shared.calculateHeight(for: model, contentConcealModel: contentConcealModel(forActionablePost: model.initialDisplayInfo.actionablePostID), filterContext: timeline.filterContext, threadedContext: threadedConversationModel?.context(for: model.initialDisplayInfo.id), contentWidth: contentWidth, totalWidth: currentUseableWidth)
        model.precalculatedHeights.insert(height, at: 0)
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
            case .notification:
                return item.id
            case .hashtag:
                return nil
            case .account:
                return item.id
            case .filteredNotificationsInfo, .loadingIndicator, .noItem:
                return nil
            }
        }
        
        var needsPrep = [MastodonPostViewModel]()
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
                    relationshipsToFetch.insert(needsRelationshipTo.id)
                }
            case .account(let accountRowViewModel):
                relationshipsToFetch.insert(accountRowViewModel.id)
            case .hashtag:
                break
            case .filteredNotificationsInfo, .loadingIndicator, .noItem:
                break
            }
        }

        for postModel in needsPrep {
            processPostViewModel(postModel)
        }
        
        let toPrep = needsPrep
        let toFetch = relationshipsToFetch
        
        Task {
            let fetchedRelationships = try await feedLoader.fetchRelationships(Array(toFetch))
            
            for postModel in toPrep {
                if postModel.fullPost?.actionablePost?.metaData.author.id == authenticatedUser?.userID {
                    postModel.prepareForDisplay(relationship: .isMe, theirAccountIsLocked: postModel.fullPost?.actionablePost?.metaData.author.locked ?? false)
                } else {
                    let relationship = fetchedRelationships.first(where: {
                        $0.info?.id == postModel.initialDisplayInfo.actionableAuthorId
                    }) ?? feedLoader.myRelationship(to: postModel.initialDisplayInfo.actionableAuthorId)
                    
                    postModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: postModel.fullPost?.actionablePost?.metaData.author.locked ?? false)
                }
                postModel.displayPrepStatus = .donePreparing
            }
            
            for item in batch {
                switch item {
                case .notification(let notificationViewModel):
                    let accountRelatingTo = notificationViewModel.needsRelationshipTo
                    if let relationship = fetchedRelationships.first(where: { fetched in
                        guard let fetchedID = fetched.info?.id else { return false }
                        return fetchedID == accountRelatingTo?.id
                    }) {
                        notificationViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: accountRelatingTo?.locked ?? false)
                    }
                    notificationViewModel.actionHandler = self
                    notificationViewModel.displayPrepStatus = .donePreparing
                case .account(let accountViewModel):
                    if let relationship = fetchedRelationships.first(where: { $0.info?.id == accountViewModel.id }) {
                        if accountViewModel.actionHandler == nil {
                            accountViewModel.actionHandler = self
                        }
                        accountViewModel.prepareForDisplay(withRelationship: relationship)
                    }
                case .post:
                    // handled above
                    break
                case .hashtag:
                    break
                case .filteredNotificationsInfo, .loadingIndicator, .noItem:
                    break
                }
            }
            
            currentlyPreparingForDisplay = nil
            
            completion?()
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

var avatarSize = AvatarSize.large
func useableWidth(fromGeoProxy geo: GeometryProxy) -> CGFloat {
    return geo.size.width - geo.safeAreaInsets.leading - geo.safeAreaInsets.trailing
}

func contentWidth(forUseableWidth useableWidth: CGFloat) -> CGFloat {
    return max(1, useableWidth - (standardPadding /*left margin*/ + spacingBetweenGutterAndContent /*avatar trailing to content leading*/ + doublePadding /*right margin*/) - avatarSize)
}

struct TimelineListView: View {
    @Environment(TimelineListViewModel.self) private var viewModel
    @Environment(TimelineQueryFilter.self) private var filterModel
    @Environment(AsyncRefreshViewModel.self) private var asyncRefreshViewModel
    @Environment(NestedScrollInteractionViewModel.self) private var nestedScrollViewModel
    
    @State var _updatedGeometry: GeometryProxy?
    @State var _updatedScrollAnchor: TimelineItem?
    @State var _updatedVisibleItems: [TimelineItem]?
    @State var _pendingGeometryUpdates = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) { // to show ALT text when needed, and donation banner, and snackbar
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
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // PROFILE TIMELINE - FILTER BOOSTS AND REPLIES
                        if filterModel.showBoostsAndRepliesFilterButton {
                            VStack(spacing: 0) {
                                Spacer()
                                    .frame(height: doublePadding)
                                
                                BoostsAndRepliesFilterButton()
                                    .padding(.horizontal, doublePadding)
                                    .frame(width: min(maxFeedContentWidth, geo.size.width))
                                
                                Spacer()
                                    .frame(height: doublePadding)
                            }
                            .id("repliesAndBoostsFilterButton")
                        }
                        
                        // PROFILE TIMELINE - FEATURED HASHTAGS
                        FeaturedHashtagsFlow(maxItemWidth: min(maxFeedContentWidth, geo.size.width) - doublePadding * 2)
                                .environment(filterModel)
                                .padding(.horizontal, doublePadding)
                                .frame(width: min(maxFeedContentWidth, geo.size.width))
                    
                        
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0) {
                                feedContents(geo)
                            }
                            .scrollTargetLayout()
                        }
                        .nestedScrollview(viewModel.timeline.isInNestedScrollview ? .inner : .notNested)
                        .onScrollPhaseChange({ oldPhase, newPhase in
                            let isNowScrolling = newPhase != .idle
                            if isNowScrolling != viewModel.isCurrentlyScrolling {
                                viewModel.isCurrentlyScrolling = isNowScrolling
                            }
                        })
                        .onScrollGeometryChange(for: Double.self) { scrollGeometry in
                            let result = viewModel.interactiveReloadTriggerModel.visiblePercent(withScrollGeometry: scrollGeometry)
                            return result
                        } action: { oldPercent, newPercent in
                            if oldPercent != newPercent {
                                viewModel.interactiveReloadTriggerModel.updateVisiblePercent(newPercent)
                            }
                        }
                        .scrollPosition(id: viewModel.scrollAnchorItemBinding, anchor: .top)
                        .onScrollTargetVisibilityChange(idType: TimelineItem.self, threshold: 0.5) { visibleRowIds in
                            queueUpdates(visibleItems: visibleRowIds)
                        }
                        .onChange(of: geo.frame(in: .global), initial: true) { _, newValue in
                            queueUpdates(geometry: geo)
                        }
                        .onChange(of: geo.safeAreaInsets, initial: true) { _, _ in
                            queueUpdates(geometry: geo)
                        }
                        .onChange(of: viewModel.scrollAnchorItem) { _, newValue in
                            queueUpdates(scrollAnchor: newValue)
                        }
                        .conditionallyRefreshable(viewModel.timeline.canPullToRefresh ? nil : {
                            guard viewModel.loadingState.canReload else { return }
                            viewModel.loadingState = .requestedReloadFromTop
                            await viewModel.refreshFromTop()
                        }
                        )
                        .accessibilityAction(named: L10n.Common.Controls.Actions.loadNewer) {
                            guard viewModel.loadingState.canReload else { return }
                            viewModel.loadingState = .requestedReloadFromTop
                            Task {
                                await viewModel.refreshFromTop()
                            }
                        }
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
                    
                    // Snackbars at the top right
                    VStack(alignment: .trailing) {
                        if viewModel.unreadCount > 0 {
                            Snackbar(barType: .newUnreadItems(viewModel.unreadCount))
                                .onTapGesture {
                                    viewModel.scrollToTop()
                                }
                        } else {
                            switch asyncRefreshViewModel.refreshButtonState {
                            case .hidden:
                                EmptyView()
                            case .newResultsExpected:
                                Snackbar(barType: .asyncRefreshUpdateAvailable)
                                    .onTapGesture {
                                        guard asyncRefreshViewModel.willRefreshFromOriginalEndpoint() else {
                                            return
                                        }
                                        viewModel.loadingState = .requestedAsyncRefreshResults
                                        Task {
                                            await viewModel.forceReload(.asyncRefreshResultsRequested)
                                        }
                                    }
                            case .fetching:
                                Snackbar(barType: .asyncRefreshUpdateFetching)
                            }
                        }
                        Spacer()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .padding(tinySpacing)
                }
            } // ZStack(alignment: .bottom)
        } // GeometryReader
        .onAppear() {
            viewModel.clearPendingActions()
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
            viewModel.loadingState = .untracked
        }
        .alert(viewModel.activeAlert.title, isPresented: viewModel.alertIsPresented, presenting: viewModel.activeAlert) { alert in
            alertContents(alert)
        } message: { alert in
            if let messageText = alert.messageText {
                Text(messageText)
            }
        }
        .sheet(isPresented: viewModel.sheetIsPresented) {
            viewModel.activeSheetContents
        }
        .overlay {
            if let activeOverlay = viewModel.activeOverlay {
                viewModel.overlayContents(activeOverlay)
            }
        }
        .environment(TimestampUpdater.timestamper(withInterval: 30))
    }
    
    private func queueUpdates(geometry: GeometryProxy? = nil, visibleItems: [TimelineItem]? = nil, scrollAnchor: TimelineItem? = nil) {
        if let geometry {
            _updatedGeometry = geometry
        }
        if let visibleItems {
            _updatedVisibleItems = visibleItems
        }
        if let scrollAnchor {
            _updatedScrollAnchor = scrollAnchor
        }
        guard !_pendingGeometryUpdates else { return }
        _pendingGeometryUpdates = true
        DispatchQueue.main.async {
            _pendingGeometryUpdates = false
            if let geo = self._updatedGeometry {
                self.viewModel.updateUseableWidth(useableWidth(fromGeoProxy: geo))
                self._updatedGeometry = nil
            }
            if let updatedVisibleItems = self._updatedVisibleItems {
                self.viewModel.visibleItemsDidChange(updatedVisibleItems)
                self._updatedVisibleItems = nil
            }
            if let updatedScrollAnchor = self._updatedScrollAnchor {
                viewModel.updateUnreadCount(scrollAnchor: updatedScrollAnchor)
                self._updatedScrollAnchor = nil
            }
        }
    }
    
    func precalculatedHeight(fromCalculations calculations: [PrecalculatedHeight], contentWidth width: CGFloat, contentConcealMode: ContentConcealViewModel.ContentDisplayMode, isShowingTranslation: Bool) -> CGFloat? {
        return calculations.first(where: { precalculated in
            precalculated.contentWidth == width
            && precalculated.contentConcealed.isShowingContent == contentConcealMode.isShowingContent
            && precalculated.contentConcealed.isShowingMedia == contentConcealMode.isShowingMedia
            && precalculated.showingTranslation == isShowingTranslation
        })?.calculatedHeight
    }
    
    @ViewBuilder func feedContents(_ geo: GeometryProxy) -> some View {
        let useableWidth = min(maxFeedContentWidth, useableWidth(fromGeoProxy: geo))
        let contentWidth = contentWidth(forUseableWidth: useableWidth)
        
        ForEach(viewModel.currentDisplaySlice, id: \.self) { item in
            switch item {
            case .loadingIndicator:
                InteractiveLoadingIndicatorRow()
                    .environment(viewModel.interactiveReloadTriggerModel)
                    .accessibilityAction(named: L10n.Common.Controls.Actions.loadOlder) {
                        switch viewModel.loadingState {
                        case .untracked:
                            viewModel.loadMoreFromBottom()
                        default:
                            break
                        }
                    }
                
            case .filteredNotificationsInfo(_, let filteredNotificationsViewModel):
                if let filteredNotificationsViewModel {
                    FilteredNotificationsRowView(contentWidth: contentWidth)
                        .environment(filteredNotificationsViewModel)
                        .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: useableWidth)
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
                        .frame(width: useableWidth)
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
                
                let contentConcealModel = viewModel.contentConcealModel(forActionablePost: postViewModel.initialDisplayInfo.actionablePostID)
                let expectedHeight: CGFloat? = postViewModel.initialDisplayInfo.id == viewModel.threadedConversationModel?.focusedID ? nil :  precalculatedHeight(fromCalculations: postViewModel.precalculatedHeights, contentWidth: contentWidth, contentConcealMode: contentConcealModel.currentMode, isShowingTranslation: postViewModel.isShowingTranslation == true)
                MastodonPostRowView(contentWidth: contentWidth, precalculatedHeight: expectedHeight, actionHandler: viewModel, threadedContext: viewModel.threadedConversationModel?.context(for: postViewModel.initialDisplayInfo.id), filterContext: viewModel.timeline.filterContext)
                .environment(postViewModel)
                .environment(contentConcealModel)
                .padding(EdgeInsets(top: 0, leading: standardPadding, bottom: 0, trailing: doublePadding))
                .frame(width: useableWidth, height: expectedHeight, alignment: .top)
#if DEBUG
                .background {
                    ZStack(alignment: .topTrailing) {
                        HStack {
                            Spacer()
                                .frame(width: AvatarSize.large + spacingBetweenGutterAndContent)
                            Rectangle()
                                .fill(viewModel.scrollAnchorItem == item ? .yellow.opacity(0.2) : .clear)
                                .frame(width: spacingBetweenGutterAndContent)
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }

                        if let expectedHeight {
                            let difference: CGFloat? = {
                                guard let actual = postViewModel.actualLayoutHeight else { return nil }
                                return actual - expectedHeight
                            }()
                            Text("calculated: \(expectedHeight)\nactual: \(String(describing: postViewModel.actualLayoutHeight))\ndifference: \(String(describing: difference))")
                                .foregroundStyle(.red)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.white.opacity(0.3))
                                }
                            FrameReader() { newFrame in
                                postViewModel.actualLayoutHeight = newFrame.size.height
                            }
                        }
                    }
                }
#endif
                .contentShape(Rectangle())
                .onTapGesture {
                    switch viewModel.timeline {
                    case .thread(let root):
                        guard root.id != postViewModel.initialDisplayInfo.id else { return }
                    case .remoteThread(remoteType: .status(let id)):
                        guard id != postViewModel.initialDisplayInfo.id else { return }
                    default:
                        break
                    }
                    postViewModel.openThreadView(actionHandler: viewModel)
                }
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
                NotificationRowView(contentWidth: contentWidth, actionHandler: viewModel)
                    .environment(notificationViewModel)
                    .padding(EdgeInsets(top: standardPadding, leading: standardPadding, bottom: standardPadding, trailing: doublePadding))
                    .frame(width: useableWidth)
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
            case .hashtag(let tagViewModel):
                switch viewModel.timeline {
                case .hashtag:
                    HashtagHeaderView(availableWidth: useableWidth - doublePadding * 2)
                        .environment(tagViewModel)
                        .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: useableWidth)
                    Divider()
                case .myFollowedHashtags:
                    HashtagHeaderView(availableWidth: useableWidth - doublePadding * 2)
                        .environment(tagViewModel)
                        .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: useableWidth)
                default:
                    HashtagRowView()
                        .padding(EdgeInsets(top: doublePadding, leading: doublePadding, bottom: standardPadding, trailing: doublePadding))
                        .frame(width: useableWidth)
                        .environment(tagViewModel)
                        .onTapGesture {
                            viewModel.presentScene(.hashtagTimeline(tagViewModel.entity), fromPost: nil, transition: .show)
                        }
                }
            case .account(let accountViewModel):
                AccountRowView(contentWidth: contentWidth)
                    .environment(accountViewModel)
                    .padding(EdgeInsets(top: standardPadding, leading: doublePadding, bottom: standardPadding, trailing: standardPadding))
                    .frame(width: useableWidth)
                    .onTapGesture {
                        accountViewModel.goToProfile()
                    }
            case .noItem:
                EmptyView()
            }
        }
        if viewModel.threadedConversationModel != nil {
            // include a spacer to indicate the end of the conversation and provide scrolling space so that if the focused post is at the end of the conversation it can still be scrolled to the top (or something near it)
            Color.clear
                .frame(height: geo.size.height * 0.5)
        }
        if !UserDefaults.standard.useBetaProfileView {
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
        case .error:
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
    
    func publishUpdate(_ update: UpdatedElement) {
        FeedCoordinator.shared.publishUpdate(update)
    }
    
    var mediaPreviewableViewController: (any MediaPreviewableViewController)? {
        return hostingViewController
    }
    
    func vote(poll: MastodonSDK.Mastodon.Entity.Poll, choices: [Int], containingPostID: Mastodon.Entity.Status.ID) async throws -> Mastodon.Entity.Poll {
        guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
        let updatedPoll = try await APIService.shared.vote(poll: poll, choices: choices, authenticationBox: authenticatedUser).value
        let updatedContainingStatus = try await APIService.shared.status(statusID: containingPostID, authenticationBox: authenticatedUser).value
        publishUpdate(.post(GenericMastodonPost.fromStatus(updatedContainingStatus)))
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
                        publishUpdate(.post(GenericMastodonPost.fromStatus(updated)))
                    }
                    clearPendingActions()
                    
            // MARK: TRANSLATE
                case .translatePost:
                    try await getTranslation(forPost: actionablePost)
                    feedLoader?.updateCachedResults({ timeline in
                        for item in timeline.items {
                            switch item {
                            case .loadingIndicator, .filteredNotificationsInfo, .hashtag, .noItem:
                                break
                            case .post(let viewModel):
                                if viewModel.fullPost?.actionablePost?.id == actionablePost.id {
                                    viewModel.isShowingTranslation = true
                                }
                            case .notification, .account:
                                break
                            }
                        }
                    })
                case .showOriginalLanguage:
                    feedLoader?.updateCachedResults({ timeline in
                        for item in timeline.items {
                            switch item {
                            case .loadingIndicator, .filteredNotificationsInfo, .hashtag, .noItem:
                                break
                            case .post(let viewModel):
                                if viewModel.fullPost?.actionablePost?.id == actionablePost.id {
                                    viewModel.isShowingTranslation = false
                                }
                            case .notification, .account:
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
                                    EmbeddedPostView(layoutWidth: 200, isSummary: false, actionHandler: nil)
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
                                    ),
                            contentIncludesQuote: postViewModel.fullQuotedPostViewModel != nil || postViewModel.placeholderQuotedPost != nil
                        )
                    )
                    
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
                    presentScene(.safari(url: url), fromPost: nil, transition: .safariPresent(animated: true))
                    
                case .sharePost:
                    sharePost(actionablePost)

            // MARK: RELATIONSHIP ACTIONS
                    
                case .follow, .unfollow, .mute, .unmute, .blockUser, .unblockUser:
                    try await doAction(action, forAccount: author)
                    isPerformingAccountAction = nil
                    
            // MARK: DEFENSIVE ACTIONS
                case .removeQuote:
                    try await doRemoveQuote(from: actionablePost, askFirst: true)
                    
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
                publishUpdate(.post(GenericMastodonPost.fromStatus(updated)))
            } catch {
                didReceiveError(error)
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
    
    func doRemoveQuote(from quotingPost: MastodonContentPost, askFirst: Bool) async throws {
        if askFirst {
            activeAlert = .confirmRemoveQuote(username: quotingPost.initialDisplayInfo().actionableAuthorDisplayName, didConfirm: { confirmed in
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
        case .blockUser:
            await doBlock(account) // always asks first
        case .unblockUser:
            await doUnblock(account) // always asks first
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
                FeedCoordinator.shared.publishUpdate(.post(GenericMastodonPost.fromStatus(updatedActionable)))
                clearPendingActions()
            }
        } catch {
            didReceiveError(error)
            clearPendingActions()
        }
    }
    
    // RELATIONSHIP ACTIONS
    
    private func doUnfollow(_ author: MastodonAccount, askFirst: Bool) async {
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
            await commitUnfollow(author.id)
        }
    }
    
    private func doMute(_ author: MastodonAccount, askFirst: Bool) async {
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
    
    private func doUnmute(_ author: MastodonAccount, askFirst: Bool) async {
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
    
    private func doBlock(_ author: MastodonAccount) async {
        await withCheckedContinuation { continuation in
            activeAlert = .confirmBlock(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                guard confirmed else { continuation.resume(); return }
                Task {
                    await self?.commitBlock(author.id)
                    continuation.resume()
                }
            })
        }
    }
    
    private func doUnblock(_ author: MastodonAccount) async {
        await withCheckedContinuation { continuation in
            activeAlert = .confirmUnblock(username: author.displayInfo.displayName, didConfirm: { [weak self] confirmed in
                guard confirmed else { continuation.resume(); return }
                Task {
                    await self?.commitUnblock(author.id)
                    continuation.resume()
                }
            })
        }
    }
    
    private func commitFollow(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.follow(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitUnfollow(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unfollow(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitMute(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.mute(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitUnmute(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unmute(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
     
    // DEFENSIVE ACTIONS
    
    func commitRemoveQuote(from quotingPost: MastodonContentPost) async {
        do {
            guard let actionablePost = quotingPost.actionablePost as? MastodonBasicPost, let quoted = actionablePost.quotedPost, let quotedId = quoted.fullPost?.id, let authenticatedUser else { throw PostActionFailure.noActionablePostId }
            let updated = try await APIService.shared.revokeQuoteAuthorization(forQuotedId: quotedId, fromQuotingId: actionablePost.id, authenticationBox: authenticatedUser)
            FeedCoordinator.shared.publishUpdate(.post(GenericMastodonPost.fromStatus(updated)))
            clearPendingActions()
        } catch {
            didReceiveError(error)
            clearPendingActions()
        }
    }
    
    private func commitBlock(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.block(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
    }
    
    private func commitUnblock(_ accountID: Mastodon.Entity.Account.ID) async {
        do {
            guard let authenticatedUser else { throw APIService.APIError.explicit(.authenticationMissing) }
            let response = try await APIService.shared.unblock(accountID, authenticationBox: authenticatedUser)
            let newRelationshipInfo = MastodonAccount.RelationshipInfo(response, fetchedAt: .now)
            FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newRelationshipInfo)))
        } catch {
            didReceiveError(error)
        }
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
                FeedCoordinator.shared.publishUpdate(.deletedPost(deletedStatus.id))
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

struct Snackbar: View {
    enum SnackbarType {
        case newUnreadItems(Int)
        case asyncRefreshUpdateAvailable
        case asyncRefreshUpdateFetching
        
        var hidesText: Bool {
            switch self {
            case .newUnreadItems, .asyncRefreshUpdateAvailable:
                return false
            case .asyncRefreshUpdateFetching:
                return true
            }
        }
    }
    
    let barType: SnackbarType
    
    var body: some View {
        let text = {
            switch barType {
            case .newUnreadItems(let unreadCount):
                return L10nLookup.Common.Controls.Timeline.Loader.unreadItemsButtonTitle(unreadCount: unreadCount)
            case .asyncRefreshUpdateAvailable, .asyncRefreshUpdateFetching:
                return L10nLookup.Common.Controls.Timeline.Loader.showMoreReplies
            }
        }()
        
        ZStack {
            HStack(spacing: tinySpacing) {
                switch barType {
                case .newUnreadItems:
                    Image(systemName: "chevron.up")
                case .asyncRefreshUpdateAvailable, .asyncRefreshUpdateFetching:
                    EmptyView()
                }
                if barType.hidesText {
                    Text(text)
                        .hidden()
                } else {
                    Text(text)
                }
            }
            .font(.footnote)
            .foregroundStyle(.white)
            .padding(EdgeInsets(top: tinySpacing, leading: standardPadding, bottom: tinySpacing, trailing: standardPadding))
            .background {
                Capsule()
                    .fill(Asset.Colors.accent.swiftUIColor)
            }
            
            switch barType {
            case .newUnreadItems, .asyncRefreshUpdateAvailable:
                EmptyView()
            case .asyncRefreshUpdateFetching:
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            }
        }
    }
}

extension MastodonTimelineType {
    var canDisplayNewItemsSnackbar: Bool {
        switch self {
        case .homeTimeline:
            true
        default:
            false
        }
    }
}

extension MastodonTimelineType {
    var canPullToRefresh: Bool {
        switch self {
        case .userPosts, .thread, .remoteThread:
            false
        default:
            true
        }
    }
    
    var isInNestedScrollview: Bool {
        switch self {
        case .userPosts:
            UserDefaults.standard.useBetaProfileView
        default:
            false
        }
    }
}

extension MastodonTimelineType {
    @MainActor
    var filterModel: TimelineQueryFilter {
        switch self {
        case .userPosts(_, let queryFilter):
            queryFilter
        default:
            TimelineQueryFilter(.unfilterable)
        }
    }
    
    var accountID: Mastodon.Entity.Account.ID? {
        switch self {
        case .userPosts(let userID, _):
            return userID
        default:
            return nil
        }
    }
}

struct FeaturedHashtagsFlow: View {
    @Environment(\.displayScale) var displayScale
    @Environment(TimelineListViewModel.self) var viewModel
    @Environment(TimelineQueryFilter.self) var filterModel
    
    var maxItemWidth: CGFloat
    
    var body: some View {
        VStack {
            if filterModel.showFeaturedHashtags && !filterModel.featuredHashtags.isEmpty {
                FlowLayout(maxItemWidth: maxItemWidth) {
                    ForEach(filterModel.featuredHashtags, id: \.self) { hashtag in
                        card(hashtag)
                            .onTapGesture {
                                if filterModel.selectedHashtag == hashtag {
                                    filterModel.selectedHashtag = nil
                                } else {
                                    filterModel.selectedHashtag = hashtag
                                }
                                Task {
                                    await viewModel.forceReload(.activityFilterUpdated)
                                }
                            }
                    }
                }
                Spacer()
                    .frame(height: doublePadding)
            } else {
                EmptyView()
            }
        }
        .task(id: filterModel.featuredHashtags) {
            Task {
                if filterModel.showFeaturedHashtags {
                    if let featuredHashtags = await viewModel.fetchFeaturedHashtags() {
                        filterModel.featuredHashtags = featuredHashtags
                        DispatchQueue.main.async {
                            // This hacky double setting is to make sure the view actually updates. Not clear why setting it once isn't enough.
                            filterModel.featuredHashtags = featuredHashtags
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder func card(_ hashtag: Mastodon.Entity.FeaturedTag) -> some View {
        let isSelected = filterModel.selectedHashtag == hashtag
        Text("#\(hashtag.name)")
        .font(.subheadline)
        .foregroundStyle(isSelected ? .white : .primary )
        .padding(.vertical, tinySpacing)
        .padding(.horizontal, doublePadding)
        .background {
            Capsule()
                .fill(isSelected ? Asset.Colors.accent.swiftUIColor : .secondary.opacity(0.2))
        }
    }
}

struct BoostsAndRepliesFilterButton: View {
    @Environment(TimelineQueryFilter.self) var filterModel
    @Environment(TimelineListViewModel.self) var viewModel
    
    var body: some View {
        HStack() {
            Button() {
                viewModel.isPresentingActivityFilter = !viewModel.isPresentingActivityFilter
            } label: {
                HStack() {
                    Text(viewModel.activityFilterButtonTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .fixedSize()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .padding(tinySpacing)
                        .background() {
                            Circle()
                                .fill(.secondary.quinary)
                        }
                }
            }
            .popover(isPresented: Binding<Bool>(
                get: { viewModel.isPresentingActivityFilter },
                set: { isPresented in viewModel.isPresentingActivityFilter = isPresented }
            ),
                     arrowEdge: .top) {
                VStack {
                    Toggle(L10nLookup.Scene.Profile.ActivityFilter.showRepliesToggleLabel,
                           isOn: Binding<Bool>(
                            get: { viewModel.includeReplies },
                            set: { newValue in viewModel.includeReplies = newValue }
                           )
                    )
                    .tint(Asset.Colors.accent.swiftUIColor)
                    Toggle(L10nLookup.Scene.Profile.ActivityFilter.showBoostsToggleLabel,
                           isOn: Binding<Bool>(
                            get: { viewModel.includeBoosts },
                            set: { newValue in viewModel.includeBoosts = newValue }
                           )
                    )
                    .tint(Asset.Colors.accent.swiftUIColor)
                    Spacer()
                        .frame(maxHeight: .infinity)
                }
                .padding(doublePadding * 2)
                .presentationDetents([.fraction(0.25)])
            }
            
            Spacer()
                .frame(maxWidth: .infinity)
        }
    }
}
