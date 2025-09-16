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

@MainActor
final public class SceneCoordinator {
    
    fileprivate static func coordinator(for view: UIView) -> SceneCoordinator? {
        return SceneDelegate.delegate(for: view)?.coordinator
    }
    
    private var disposeBag = Set<AnyCancellable>()
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    
    var authenticationBox: MastodonAuthenticationBox? {
        AuthenticationServiceProvider.shared.currentActiveUser.value
    }
    
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

        NotificationService.shared.requestRevealNotificationPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: {
                [weak self] pushNotification in
                guard let self else { return }
                Task { @MainActor in
                    guard let currentActiveAuthenticationBox = self.authenticationBox else { return }
                    let accessToken = pushNotification.accessToken     // use raw accessToken value without normalize
                    if currentActiveAuthenticationBox.userAuthorization.accessToken == accessToken {
                        // do nothing if notification for current account
                        return
                    } else {
                        // switch to notification's account
                        do {
                            guard let authenticationBox = AuthenticationServiceProvider.shared.activateExistingUserToken(accessToken) else {
                                return
                            }

                            self.setup()
                            try await Task.sleep(nanoseconds: .nanosPerUnit * 1)

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
                            guard let type = Mastodon.Entity.NotificationType(rawValue: pushNotification.notificationType) else { return }
                            guard let me = authenticationBox.cachedAccount else { return }
                            let notificationID = String(pushNotification.notificationID)

                            switch type {
                            case .follow:
                                let account = try await APIService.shared.notification(
                                    notificationID: notificationID,
                                    authenticationBox: authenticationBox
                                ).value.account

                                let relationship = try await APIService.shared.relationship(forAccounts: [account], authenticationBox: authenticationBox).value.first

                                let profileType: ProfileViewController.ProfileType = me == account ? .me(me) : .notMe(me: me, displayAccount: account, relationship: relationship)
                                _ = self.present(
                                    scene: .profile(profileType),
                                    from: from,
                                    transition: .show
                                )
                            case .followRequest:
                                // do nothing
                                break
                            case .mention, .reblog, .favourite, .poll, .status:
                                let threadViewModel = RemoteThreadViewModel(
                                    authenticationBox: authenticationBox,
                                    notificationID: notificationID
                                )
                                _ = self.present(
                                    scene: .thread(viewModel: threadViewModel),
                                    from: from,
                                    transition: .show
                                )
                            case .moderationWarning:
                                break
                            default:
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
        case formSheet([UISheetPresentationController.Detent]?)
        case none
    }

    enum Scene {
        // onboarding
        case welcome
        case mastodonPickServer(viewMode: MastodonPickServerViewModel)
        case mastodonRegister(viewModel: MastodonRegisterViewModel)
        case mastodonPrivacyPolicies(viewModel: PolicyViewModel)
        case mastodonServerRules(viewModel: MastodonServerRulesView.ViewModel)
        case mastodonConfirmEmail(viewModel: MastodonConfirmEmailViewModel)
        case mastodonResendEmail(viewModel: MastodonResendEmailViewModel)
        case mastodonWebView(viewModel: WebViewModel)
        case mastodonLogin(authenticationViewModel: AuthenticationViewModel, suggestedDomain: String?)

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
        case profile(ProfileViewController.ProfileType)
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
        case notificationPolicy(viewModel: NotificationPolicyViewModel)
        case notificationRequests(viewModel: NotificationRequestsViewModel)
        case accountNotificationTimeline(request: Mastodon.Entity.NotificationRequest)

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
    
    @MainActor
    func setup() {
        let rootViewController: UIViewController

        switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                let viewController = MainTabBarController(authenticationBox: authenticationBox)
                self.splitViewController = nil
                self.tabBarController = viewController
                rootViewController = viewController
            default:
                let splitViewController = RootSplitViewController(authenticationBox: authenticationBox)
                self.splitViewController = splitViewController
                self.tabBarController = splitViewController.contentSplitViewController.mainTabBarController
                rootViewController = splitViewController
        }
        
        // this feels wrong
        sceneDelegate.window?.rootViewController = rootViewController                   // base: main
        self.rootViewController = rootViewController

        if authenticationBox == nil {                                                        // entry #1: welcome
            DispatchQueue.main.async {
                _ = self.present(
                    scene: .welcome,
                    from: rootViewController, // self.sceneDelegate.window?.rootViewController,
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

        case .formSheet(let detents):
            viewController.modalPresentationStyle = .formSheet
            if let sheetPresentation = viewController.sheetPresentationController {
                sheetPresentation.detents = detents ?? [.medium(), .large()]
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
            viewController = MastodonPickServerViewController(coordinator: self, viewModel: viewModel)
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
        case .mastodonLogin(let authenticationViewModel, let suggestedDomain):
            let loginViewController = MastodonLoginViewController(authenticationViewModel: authenticationViewModel,
                                                                  suggestedDomain: suggestedDomain)
            loginViewController.delegate = self

            viewController = loginViewController
        case .mastodonPrivacyPolicies(let viewModel):
            let policyViewController = PolicyTableViewController(coordinator: self, viewModel: viewModel)
            viewController = policyViewController
        case .mastodonResendEmail(let viewModel):
            let _viewController = MastodonResendEmailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonWebView(let viewModel):
            let _viewController = WebViewController(viewModel)
            viewController = _viewController
        case .searchDetail(let viewModel):
            let _viewController = SearchDetailViewController(authenticationBox: viewModel.authenticationBox)
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .searchResult(let viewModel):
            if viewModel.searchScope == .posts {
                viewController = TimelineListViewController(.searchPosts(viewModel.searchText))
            } else {
                let searchResultViewController = SearchResultViewController()
                searchResultViewController.viewModel = viewModel
                viewController = searchResultViewController
            }
        case .compose(let viewModel):
            let _viewController = ComposeViewController(viewModel: viewModel)
            viewController = _viewController
        case .thread(let viewModel):
            if let viewModel = viewModel as? RemoteThreadViewModel {
                viewController = TimelineListViewController(.remoteThread(root: viewModel.entityType))
            } else {
                guard let rootStatus = viewModel.root?.record, let rootPost = GenericMastodonPost.fromStatus(rootStatus.entity) as? MastodonContentPost else { return nil }
                viewController = TimelineListViewController(.thread(root: rootPost))
            }
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
        case .profile(let profileType):
            let _viewController = ProfileViewController(profileType, authenticationBox: AuthenticationServiceProvider.shared.currentActiveUser.value!)
            viewController = _viewController
        case .bookmark(let viewModel):
            viewController = TimelineListViewController(.myBookmarks)
        case .followedTags(let viewModel):
            guard let authenticationBox else { return nil }
            
            viewController = FollowedTagsViewController(authenticationBox: authenticationBox, viewModel: viewModel)
        case .favorite(let viewModel):
            viewController = TimelineListViewController(.myFavorites)
        case .follower(let viewModel):
            let followerListViewController = FollowerListViewController(viewModel: viewModel)
            viewController = followerListViewController
        case .following(let viewModel):
            let followingListViewController = FollowingListViewController(viewModel: viewModel)
            viewController = followingListViewController
        case .familiarFollowers(let viewModel):
            viewController = FamiliarFollowersViewController(viewModel: viewModel)
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
            guard let presentedOn = sender, let authenticationBox = self.authenticationBox
            else { return nil }
            
            let accountName = authenticationBox.authentication.username
            
            let settingsCoordinator = SettingsCoordinator(presentedOn: presentedOn,
                                                          accountName: accountName,
                                                          setting: setting,
                                                          appContext: AppContext.shared,
                                                          authenticationBox: authenticationBox,
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
        case .notificationPolicy(let viewModel):
            viewController = NotificationPolicyViewController(viewModel)
        case .accountNotificationTimeline(let request):
            viewController = TimelineListViewController(.notifications(.fromRequest(request)))
        }

        return viewController
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
    func logout(_ user: MastodonAuthentication, presentingFrom viewController: UIViewController) {

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
            guard let self else { return }

            NotificationService.shared.clearNotificationCountForActiveUser()

            Task { @MainActor in
                try await AuthenticationServiceProvider.shared.signOutMastodonUser(
                    authentication: user
                )
                self.setup()
                PersistenceManager.shared.removeAllCaches(forUser: user)
                try await BodegaPersistence.removeUser(user)
            }

        }

        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)

        (viewController.navigationController ?? viewController).present(alertController, animated: true)
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
        guard let privacyURL = URL(string: "https://joinmastodon.org/ios/privacy") else { return }
        _ = present(scene: .safari(url: privacyURL),
                    from: settingsCoordinator.navigationController,
                    transition: .safariPresent(animated: true))

    }

    func openProfileSettingsURL(_ settingsCoordinator: SettingsCoordinator) {
        guard let authenticationBox else { return }

        let domain = authenticationBox.domain
        let profileSettingsURL = Mastodon.API.profileSettingsURL(domain: domain)

        let authenticationController = MastodonAuthenticationController(authenticateURL: profileSettingsURL)

        authenticationController.authenticationSession?.presentationContextProvider = settingsCoordinator
        authenticationController.authenticationSession?.start()

        self.mastodonAuthenticationController = authenticationController
    }
}

public extension UIViewController {
    var sceneCoordinator: SceneCoordinator? {
        guard let view = viewIfLoaded else { assert(false); return nil }
        if let coordinator = SceneCoordinator.coordinator(for: view) {
            return coordinator
        }
        if let navView = navigationController?.view {
            return SceneCoordinator.coordinator(for: navView)
        }
        return nil
    }
}
