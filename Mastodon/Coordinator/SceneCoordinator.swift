//
//  SceneCoordinator.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.

import UIKit
import Combine
import SafariServices
import CoreDataStack
import MastodonSDK
import MastodonCore
import MastodonAsset
import MastodonLocalization
import MBProgressHUD

final public class SceneCoordinator {
    
    private var disposeBag = Set<AnyCancellable>()
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    private(set) weak var appContext: AppContext!
    
    private(set) var authContext: AuthContext?
    
    let id = UUID().uuidString
    
    private(set) weak var tabBarController: MainTabBarController!
    private(set) weak var splitViewController: RootSplitViewController?
    private(set) weak var rootViewController: UIViewController?

    private(set) var secondaryStackHashValues = Set<Int>()
    var childCoordinator: Coordinator?

    private var mastodonAuthenticationController: MastodonAuthenticationController?
    
    init(
        scene: UIScene,
        sceneDelegate: SceneDelegate,
        appContext: AppContext
    ) {
        self.scene = scene
        self.sceneDelegate = sceneDelegate
        self.appContext = appContext
        
        scene.session.sceneCoordinator = self

        appContext.notificationService.requestRevealNotificationPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                [weak self] pushNotification in
                guard let self else { return }
                Task { @MainActor in
                    guard let currentActiveAuthenticationBox = self.authContext?.mastodonAuthenticationBox else { return }
                    let accessToken = pushNotification.accessToken     // use raw accessToken value without normalize
                    if currentActiveAuthenticationBox.userAuthorization.accessToken == accessToken {
                        // do nothing if notification for current account
                        return
                    } else {
                        // switch to notification's account
                        do {
                            guard let authentication = AuthenticationServiceProvider.shared.authentications.first(where: { $0.userAccessToken == accessToken }) else {
                                return
                            }
                            let domain = authentication.domain
                            let userID = authentication.userID
                            let isSuccess = try await appContext.authenticationService.activeMastodonUser(domain: domain, userID: userID)
                            guard isSuccess else { return }

                            self.setup()
                            try await Task.sleep(nanoseconds: .second * 1)

                            // redirect to notifications tab
                            self.switchToTabBar(tab: .notifications)

                            // Note:
                            // show (push) on phone and pad
                            let from: UIViewController? = {
                                if let splitViewController = self.splitViewController {
                                    if splitViewController.compactMainTabBarViewController.topMost?.view.window != nil {
                                        // compact
                                        return splitViewController.compactMainTabBarViewController.topMost
                                    } else {
                                        // expand
                                        return splitViewController.contentSplitViewController.mainTabBarController.topMost
                                    }
                                } else {
                                    return self.tabBarController.topMost
                                }
                            }()

                            // show notification related content
                            guard let type = Mastodon.Entity.Notification.NotificationType(rawValue: pushNotification.notificationType) else { return }
                            guard let authContext = self.authContext else { return }
                            guard let me = authContext.mastodonAuthenticationBox.authentication.account() else { return }
                            let notificationID = String(pushNotification.notificationID)

                            switch type {
                            case .follow:
                                let account = try await appContext.apiService.notification(
                                    notificationID: notificationID,
                                    authenticationBox: authContext.mastodonAuthenticationBox
                                ).value.account

                                let relationship = try await appContext.apiService.relationship(forAccounts: [account], authenticationBox: authContext.mastodonAuthenticationBox).value.first

                                let profileViewModel = ProfileViewModel(
                                    context: appContext,
                                    authContext: authContext,
                                    account: account,
                                    relationship: relationship,
                                    me: me
                                )
                                _ = self.present(
                                    scene: .profile(viewModel: profileViewModel),
                                    from: from,
                                    transition: .show
                                )
                            case .followRequest:
                                // do nothing
                                break
                            case .mention, .reblog, .favourite, .poll, .status:
                                let threadViewModel = RemoteThreadViewModel(
                                    context: appContext,
                                    authContext: authContext,
                                    notificationID: notificationID
                                )
                                _ = self.present(
                                    scene: .thread(viewModel: threadViewModel),
                                    from: from,
                                    transition: .show
                                )
                            case .moderationWarning:
                                break
                            case ._other:
                                assertionFailure()
                                break
                            }

                        } catch {
                            assertionFailure(error.localizedDescription)
                            return
                        }
                    }
                }   // end Task
            })
            .store(in: &disposeBag)
    }
}

extension SceneCoordinator {
    enum Transition {
        case show                           // push
        case showDetail                     // replace
        case modal(animated: Bool, completion: (() -> Void)? = nil)
        case popover(sourceView: UIView)
        case custom(transitioningDelegate: UIViewControllerTransitioningDelegate)
        case customPush(animated: Bool)
        case safariPresent(animated: Bool, completion: (() -> Void)? = nil)
        case alertController(animated: Bool, completion: (() -> Void)? = nil)
        case activityViewControllerPresent(animated: Bool, completion: (() -> Void)? = nil)
        case formSheet
        case none
    }

    enum Scene {
        // onboarding
        case welcome
        case mastodonPickServer(viewMode: MastodonPickServerViewModel)
        case mastodonRegister(viewModel: MastodonRegisterViewModel)
        case mastodonPrivacyPolicies(viewModel: PrivacyViewModel)
        case mastodonServerRules(viewModel: MastodonServerRulesViewModel)
        case mastodonConfirmEmail(viewModel: MastodonConfirmEmailViewModel)
        case mastodonResendEmail(viewModel: MastodonResendEmailViewModel)
        case mastodonWebView(viewModel: WebViewModel)
        case mastodonLogin

        // search
        case searchDetail(viewModel: SearchDetailViewModel)
        case searchResult(viewModel: SearchResultViewModel)

        // compose
        case compose(viewModel: ComposeViewModel)
        case editStatus(viewModel: ComposeViewModel)
        
        // thread
        case thread(viewModel: ThreadViewModel)
        case editHistory(viewModel: StatusEditHistoryViewModel)
        
        // Hashtag Timeline
        case hashtagTimeline(viewModel: HashtagTimelineViewModel)

        // profile
        case accountList(viewModel: AccountListViewModel)
        case profile(viewModel: ProfileViewModel)
        case favorite(viewModel: FavoriteViewModel)
        case follower(viewModel: FollowerListViewModel)
        case following(viewModel: FollowingListViewModel)
        case familiarFollowers(viewModel: FamiliarFollowersViewModel)
        case rebloggedBy(viewModel: UserListViewModel)
        case favoritedBy(viewModel: UserListViewModel)
        case bookmark(viewModel: BookmarkViewModel)
        case followedTags(viewModel: FollowedTagsViewModel)

        // setting
        case settings(setting: Setting)

        // Notifications
        case notificationRequests(viewModel: NotificationRequestsViewModel)

        // report
        case report(viewModel: ReportViewModel)
        case reportServerRules(viewModel: ReportServerRulesViewModel)
        case reportStatus(viewModel: ReportStatusViewModel)
        case reportSupplementary(viewModel: ReportSupplementaryViewModel)
        case reportResult(viewModel: ReportResultViewModel)

        // suggestion account
        case suggestionAccount(viewModel: SuggestionAccountViewModel)
        
        // media preview
        case mediaPreview(viewModel: MediaPreviewViewModel)
        
        // misc
        case safari(url: URL)
        case alertController(alertController: UIAlertController)
        case activityViewController(activityViewController: UIActivityViewController, sourceView: UIView?, barButtonItem: UIBarButtonItem?)

        var isOnboarding: Bool {
            switch self {
                case .welcome,
                        .mastodonPickServer,
                        .mastodonRegister,
                        .mastodonLogin,
                        .mastodonServerRules,
                        .mastodonConfirmEmail,
                        .mastodonResendEmail:
                    return true
                default:
                    return false
            }
        }
    }   // end enum Scene { }
}

extension SceneCoordinator {
    
    func setup() {
        let rootViewController: UIViewController

        let _authentication = AuthenticationServiceProvider.shared.authenticationSortedByActivation().first
        let _authContext = _authentication.flatMap { AuthContext(authentication: $0) }
        self.authContext = _authContext

        switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                let viewController = MainTabBarController(context: appContext, coordinator: self, authContext: _authContext)
                self.splitViewController = nil
                self.tabBarController = viewController
                rootViewController = viewController
            default:
                let splitViewController = RootSplitViewController(context: appContext, coordinator: self, authContext: _authContext)
                self.splitViewController = splitViewController
                self.tabBarController = splitViewController.contentSplitViewController.mainTabBarController
                rootViewController = splitViewController
        }
        
        sceneDelegate.window?.rootViewController = rootViewController                   // base: main
        self.rootViewController = rootViewController

        if _authContext == nil {                                                        // entry #1: welcome
            DispatchQueue.main.async {
                _ = self.present(
                    scene: .welcome,
                    from: self.sceneDelegate.window?.rootViewController,
                    transition: .modal(animated: true, completion: nil)
                )
            }
        }
    }

    @MainActor
    @discardableResult
    func present(scene: Scene, from sender: UIViewController? = nil, transition: Transition) -> UIViewController? {
        guard let viewController = get(scene: scene, from: sender) else {
            return nil
        }
        guard var presentingViewController = sender ?? sceneDelegate.window?.rootViewController?.topMost else {
            return nil
        }
        // adapt for child controller
        if let navigationControllerVisibleViewController = presentingViewController.navigationController?.visibleViewController {
            switch viewController {
                case is ProfileViewController:
                    let title: String = {
                        let title = navigationControllerVisibleViewController.navigationItem.title ?? ""
                        return title.count > 10 ? "" : title
                    }()
                    let barButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
                    barButtonItem.tintColor = .white
                    navigationControllerVisibleViewController.navigationItem.backBarButtonItem = barButtonItem
                default:
                    navigationControllerVisibleViewController.navigationItem.backBarButtonItem = nil
            }
        }
        
        if let mainTabBarController = presentingViewController as? MainTabBarController,
           let navigationController = mainTabBarController.selectedViewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            presentingViewController = topViewController
        }

        switch transition {
        case .none:
            // do nothing
            break
        case .show:
            presentingViewController.show(viewController, sender: sender)
        case .showDetail:
            secondaryStackHashValues.insert(viewController.hashValue)
            let navigationController = AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
            presentingViewController.showDetailViewController(navigationController, sender: sender)

        case .modal(let animated, let completion):
            let modalNavigationController: UINavigationController = {
                if scene.isOnboarding {
                    return OnboardingNavigationController(rootViewController: viewController)
                } else {
                    return AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
                }
            }()
            modalNavigationController.modalPresentationCapturesStatusBarAppearance = true
            if let adaptivePresentationControllerDelegate = viewController as? UIAdaptivePresentationControllerDelegate {
                modalNavigationController.presentationController?.delegate = adaptivePresentationControllerDelegate
            }
            presentingViewController.present(modalNavigationController, animated: animated, completion: completion)
        case .popover(let sourceView):
            viewController.modalPresentationStyle = .popover
            viewController.popoverPresentationController?.sourceView = sourceView
            (splitViewController ?? presentingViewController)?.present(viewController, animated: true, completion: nil)
        case .custom(let transitioningDelegate):
            viewController.modalPresentationStyle = .custom
            viewController.transitioningDelegate = transitioningDelegate
            viewController.modalPresentationCapturesStatusBarAppearance = true
            (splitViewController ?? presentingViewController)?.present(viewController, animated: true, completion: nil)

        case .customPush(let animated):
            // set delegate in view controller
            assert(sender?.navigationController?.delegate != nil)
            sender?.navigationController?.pushViewController(viewController, animated: animated)

        case .safariPresent(let animated, let completion):
            if UserDefaults.shared.preferredUsingDefaultBrowser, case let .safari(url) = scene {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                viewController.modalPresentationCapturesStatusBarAppearance = true
                presentingViewController.present(viewController, animated: animated, completion: completion)
            }

        case .alertController(let animated, let completion):
            viewController.modalPresentationCapturesStatusBarAppearance = true
            presentingViewController.present(viewController, animated: animated, completion: completion)

        case .activityViewControllerPresent(let animated, let completion):
            viewController.modalPresentationCapturesStatusBarAppearance = true
            presentingViewController.present(viewController, animated: animated, completion: completion)

        case .formSheet:
            viewController.modalPresentationStyle = .formSheet
            if let sheetPresentation = viewController.sheetPresentationController {
                sheetPresentation.detents = [.large(), .medium()]
            }
            presentingViewController.present(viewController, animated: true)
        }

        return viewController
    }

    func switchToTabBar(tab: Tab) {
        splitViewController?.contentSplitViewController.currentSupplementaryTab = tab
        
        splitViewController?.compactMainTabBarViewController.selectedIndex = tab.rawValue
        splitViewController?.compactMainTabBarViewController.currentTab = tab
        
        tabBarController.selectedIndex = tab.rawValue
        tabBarController.currentTab = tab
    }
}

private extension SceneCoordinator {
    
    func get(scene: Scene, from sender: UIViewController? = nil) -> UIViewController? {
        let viewController: UIViewController?
        
        switch scene {
        case .welcome:
            let _viewController = WelcomeViewController()
            viewController = _viewController
        case .mastodonPickServer(let viewModel):
            let _viewController = MastodonPickServerViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonRegister(let viewModel):
            let _viewController = MastodonRegisterViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonServerRules(let viewModel):
            let _viewController = MastodonServerRulesViewController(viewModel: viewModel)
            viewController = _viewController
        case .mastodonConfirmEmail(let viewModel):
            let _viewController = MastodonConfirmEmailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonLogin:
            let loginViewController = MastodonLoginViewController(appContext: appContext,
                                                                  authenticationViewModel: AuthenticationViewModel(context: appContext, coordinator: self, isAuthenticationExist: false),
                                                                  sceneCoordinator: self)
            loginViewController.delegate = self

            viewController = loginViewController
        case .mastodonPrivacyPolicies(let viewModel):
            let privacyViewController = PrivacyTableViewController(context: appContext, coordinator: self, viewModel: viewModel)
            viewController = privacyViewController
        case .mastodonResendEmail(let viewModel):
            let _viewController = MastodonResendEmailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonWebView(let viewModel):
            let _viewController = WebViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .searchDetail(let viewModel):
            let _viewController = SearchDetailViewController(appContext: appContext, sceneCoordinator: self, authContext: viewModel.authContext)
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .searchResult(let viewModel):
            let searchResultViewController = SearchResultViewController()
            searchResultViewController.context = appContext
            searchResultViewController.coordinator = self
            searchResultViewController.viewModel = viewModel
            viewController = searchResultViewController
        case .compose(let viewModel):
            let _viewController = ComposeViewController(viewModel: viewModel)
            viewController = _viewController
        case .thread(let viewModel):
            let _viewController = ThreadViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .editHistory(let viewModel):
            let editHistoryViewController = StatusEditHistoryViewController(viewModel: viewModel)
            viewController = editHistoryViewController
        case .hashtagTimeline(let viewModel):
            let _viewController = HashtagTimelineViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .accountList(let viewModel):
            let accountListViewController = AccountListViewController()
            accountListViewController.viewModel = viewModel
            viewController = accountListViewController
        case .profile(let viewModel):
            let _viewController = ProfileViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .bookmark(let viewModel):
            let _viewController = BookmarkViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .followedTags(let viewModel):
            guard let authContext else { return nil }

            viewController = FollowedTagsViewController(appContext: appContext, sceneCoordinator: self, authContext: authContext, viewModel: viewModel)
        case .favorite(let viewModel):
            let _viewController = FavoriteViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .follower(let viewModel):
            let followerListViewController = FollowerListViewController(viewModel: viewModel, coordinator: self, context: appContext)
            viewController = followerListViewController
        case .following(let viewModel):
            let followingListViewController = FollowingListViewController(viewModel: viewModel, coordinator: self, context: appContext)
            viewController = followingListViewController
        case .familiarFollowers(let viewModel):
            viewController = FamiliarFollowersViewController(viewModel: viewModel, context: appContext, coordinator: self)
        case .rebloggedBy(let viewModel):
            let _viewController = RebloggedByViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .favoritedBy(let viewModel):
            let _viewController = FavoritedByViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .report(let viewModel):
            viewController = ReportViewController(viewModel: viewModel)
        case .reportServerRules(let viewModel):
            let _viewController = ReportServerRulesViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .reportStatus(let viewModel):
            let _viewController = ReportStatusViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .reportSupplementary(let viewModel):
            let _viewController = ReportSupplementaryViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .reportResult(let viewModel):
            let _viewController = ReportResultViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .suggestionAccount(let viewModel):
            let _viewController = SuggestionAccountViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mediaPreview(let viewModel):
            let _viewController = MediaPreviewViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .safari(let url):
            guard let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https" else {
                return nil
            }
            let _viewController = SFSafariViewController(url: url)
            _viewController.preferredBarTintColor = SystemTheme.navigationBarBackgroundColor
            _viewController.preferredControlTintColor = Asset.Colors.Brand.blurple.color
            viewController = _viewController

        case .alertController(let alertController):
            if let popoverPresentationController = alertController.popoverPresentationController {
                assert(
                    popoverPresentationController.sourceView != nil ||
                    popoverPresentationController.sourceRect != .zero ||
                    popoverPresentationController.barButtonItem != nil
                )
            }
            viewController = alertController
        case .activityViewController(let activityViewController, let sourceView, let barButtonItem):
            activityViewController.popoverPresentationController?.sourceView = sourceView
            activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
            viewController = activityViewController
        case .settings(let setting):
            guard let presentedOn = sender,
                  let accountName = authContext?.mastodonAuthenticationBox.authentication.username,
                  let authContext
            else { return nil }

            let settingsCoordinator = SettingsCoordinator(presentedOn: presentedOn,
                                                          accountName: accountName,
                                                          setting: setting,
                                                          appContext: appContext,
                                                          authContext: authContext,
                                                          sceneCoordinator: self
            )
            settingsCoordinator.delegate = self
            settingsCoordinator.start()

            viewController = settingsCoordinator.navigationController
            childCoordinator = settingsCoordinator

        case .editStatus(let viewModel):
            let composeViewController = ComposeViewController(viewModel: viewModel)
            viewController = composeViewController
        case .notificationRequests(let viewModel):
            viewController = NotificationRequestsTableViewController(viewModel: viewModel)
        }

        setupDependency(for: viewController as? NeedsDependency)

        return viewController
    }

    private func setupDependency(for needs: NeedsDependency?) {
        needs?.context = appContext
        needs?.coordinator = self
    }
}

//MARK: - Loading

public extension SceneCoordinator {

    @MainActor
    func showLoading() {
        showLoading(on: rootViewController)
    }

    @MainActor
    func showLoading(on viewController: UIViewController?) {
        guard let viewController else { return }
        
        /// Don't add HUD twice
        guard MBProgressHUD.forView(viewController.view) == nil else { return }
        
        MBProgressHUD.showAdded(to: viewController.view, animated: true)
    }

    @MainActor
    func hideLoading() {
        hideLoading(on: rootViewController)
    }

    @MainActor
    func hideLoading(on viewController: UIViewController?) {
        guard let viewController else { return }

        MBProgressHUD.hide(for: viewController.view, animated: true)
    }
}

//MARK: - MastodonLoginViewControllerDelegate

extension SceneCoordinator: MastodonLoginViewControllerDelegate {
    func backButtonPressed(_ viewController: MastodonLoginViewController) {
        viewController.navigationController?.popViewController(animated: true)
    }
}

//MARK: - SettingsCoordinatorDelegate
extension SceneCoordinator: SettingsCoordinatorDelegate {
    func logout(_ settingsCoordinator: SettingsCoordinator) {

        let preferredStyle: UIAlertController.Style

        if UIDevice.current.userInterfaceIdiom == .phone {
            preferredStyle = .actionSheet
        } else {
            preferredStyle = .alert
        }

        let alertController = UIAlertController(
            title: L10n.Common.Alerts.SignOut.title,
            message: L10n.Common.Alerts.SignOut.message,
            preferredStyle: preferredStyle
        )

        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel)
        let signOutAction = UIAlertAction(title: L10n.Common.Alerts.SignOut.confirm, style: .destructive) { [weak self] _ in
            guard let self, let authContext = self.authContext else { return }

            self.appContext.notificationService.clearNotificationCountForActiveUser()

            Task { @MainActor in
                try await self.appContext.authenticationService.signOutMastodonUser(
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
                let userIdentifier = authContext.mastodonAuthenticationBox
                FileManager.default.invalidateHomeTimelineCache(for: userIdentifier)
                FileManager.default.invalidateNotificationsAll(for: userIdentifier)
                FileManager.default.invalidateNotificationsMentions(for: userIdentifier)
                self.setup()
            }

        }

        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)

        settingsCoordinator.navigationController.present(alertController, animated: true)
    }

    @MainActor
    func openGithubURL(_ settingsCoordinator: SettingsCoordinator) {
        guard let githubURL = URL(string: "https://github.com/mastodon/mastodon-ios") else { return }

        _ = present(
            scene: .safari(url: githubURL),
            from: settingsCoordinator.navigationController,
            transition: .safariPresent(animated: true)
        )
    }

    @MainActor
    func openPrivacyURL(_ settingsCoordinator: SettingsCoordinator) {
        guard let authContext else { return }

        let domain = authContext.mastodonAuthenticationBox.domain
        let privacyURL = Mastodon.API.privacyURL(domain: domain)

        _ = present(scene: .safari(url: privacyURL),
                    from: settingsCoordinator.navigationController,
                    transition: .safariPresent(animated: true))

    }

    func openProfileSettingsURL(_ settingsCoordinator: SettingsCoordinator) {
        guard let authContext else { return }

        let domain = authContext.mastodonAuthenticationBox.domain
        let profileSettingsURL = Mastodon.API.profileSettingsURL(domain: domain)

        let authenticationController = MastodonAuthenticationController(context: appContext, authenticateURL: profileSettingsURL)

        authenticationController.authenticationSession?.presentationContextProvider = settingsCoordinator
        authenticationController.authenticationSession?.start()

        self.mastodonAuthenticationController = authenticationController
    }
}
