//
//  SceneCoordinator.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.

import UIKit
import Combine
import SafariServices
import CoreDataStack
import PanModal
import MastodonSDK
import MastodonCore
import MastodonAsset
import MastodonLocalization

final public class SceneCoordinator {
    
    private var disposeBag = Set<AnyCancellable>()
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    private(set) weak var appContext: AppContext!
    
    private(set) var authContext: AuthContext?
    
    let id = UUID().uuidString
    
    private(set) weak var tabBarController: MainTabBarController!
    private(set) weak var splitViewController: RootSplitViewController?
    private(set) var wizardViewController: WizardViewController?
    
    private(set) var secondaryStackHashValues = Set<Int>()
    
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
            .sink(receiveValue: { [weak self] pushNotification in
                guard let self = self else { return }
                Task {
                    guard let currentActiveAuthenticationBox = self.authContext?.mastodonAuthenticationBox else { return }
                    let accessToken = pushNotification.accessToken     // use raw accessToken value without normalize
                    if currentActiveAuthenticationBox.userAuthorization.accessToken == accessToken {
                        // do nothing if notification for current account
                        return
                    } else {
                        // switch to notification's account
                        let request = MastodonAuthentication.sortedFetchRequest
                        request.predicate = MastodonAuthentication.predicate(userAccessToken: accessToken)
                        request.returnsObjectsAsFaults = false
                        request.fetchLimit = 1
                        do {
                            guard let authentication = try appContext.managedObjectContext.fetch(request).first else {
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
                            
                            // Delay in next run loop
                            DispatchQueue.main.async { [weak self] in
                                guard let self = self else { return }
                                
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
                                let notificationID = String(pushNotification.notificationID)
                                
                                switch type {
                                case .follow:
                                    let profileViewModel = RemoteProfileViewModel(context: appContext, authContext: authContext, notificationID: notificationID)
                                    _ = self.present(scene: .profile(viewModel: profileViewModel), from: from, transition: .show)
                                case .followRequest:
                                    // do nothing
                                    break
                                case .mention, .reblog, .favourite, .poll, .status:
                                    let threadViewModel = RemoteThreadViewModel(context: appContext, authContext: authContext, notificationID: notificationID)
                                    _ = self.present(scene: .thread(viewModel: threadViewModel), from: from, transition: .show)
                                case ._other:
                                    assertionFailure()
                                    break
                                }
                            }   // end DispatchQueue.main.async
                            
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
        case panModal
        case custom(transitioningDelegate: UIViewControllerTransitioningDelegate)
        case customPush(animated: Bool)
        case safariPresent(animated: Bool, completion: (() -> Void)? = nil)
        case alertController(animated: Bool, completion: (() -> Void)? = nil)
        case activityViewControllerPresent(animated: Bool, completion: (() -> Void)? = nil)
    }
    
    enum Scene {
        // onboarding
        case welcome
        case mastodonPickServer(viewMode: MastodonPickServerViewModel)
        case mastodonRegister(viewModel: MastodonRegisterViewModel)
        case mastodonServerRules(viewModel: MastodonServerRulesViewModel)
        case mastodonConfirmEmail(viewModel: MastodonConfirmEmailViewModel)
        case mastodonResendEmail(viewModel: MastodonResendEmailViewModel)
        case mastodonWebView(viewModel: WebViewModel)
        case mastodonLogin

        // search
        case searchDetail(viewModel: SearchDetailViewModel)

        // compose
        case compose(viewModel: ComposeViewModel)
        
        // thread
        case thread(viewModel: ThreadViewModel)
        
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
        case settings(viewModel: SettingsViewModel)
        
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
        
        do {
            let request = MastodonAuthentication.activeSortedFetchRequest   // use active order
            let _authentication = try appContext.managedObjectContext.fetch(request).first
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

            if _authContext == nil {                                                        // entry #1: welcome
                DispatchQueue.main.async {
                    _ = self.present(
                        scene: .welcome,
                        from: self.sceneDelegate.window?.rootViewController,
                        transition: .modal(animated: true, completion: nil)
                    )
                }
            } else {
                let wizardViewController = WizardViewController()
                if !wizardViewController.items.isEmpty,
                   let delegate = rootViewController as? WizardViewControllerDelegate
                {
                    // do not add as child view controller.
                    // otherwise, the tab bar controller will add as a new tab
                    wizardViewController.delegate = delegate
                    wizardViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    wizardViewController.view.frame = rootViewController.view.bounds
                    rootViewController.view.addSubview(wizardViewController.view)
                    self.wizardViewController = wizardViewController
                }
            }
            
        } catch {
            assertionFailure(error.localizedDescription)
            Task {
                try? await Task.sleep(nanoseconds: .second * 2)
                setup()                                                                     // entry #2: retry
            }   // end Task
        }
    }

    @MainActor
    @discardableResult
    func present(scene: Scene, from sender: UIViewController?, transition: Transition) -> UIViewController? {
        guard let viewController = get(scene: scene) else {
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

        case .panModal:
            guard let panModalPresentable = viewController as? PanModalPresentable & UIViewController else {
                assertionFailure()
                return nil
            }
            
            // https://github.com/slackhq/PanModal/issues/74#issuecomment-572426441
            panModalPresentable.modalPresentationStyle = .custom
            panModalPresentable.modalPresentationCapturesStatusBarAppearance = true
            panModalPresentable.transitioningDelegate = PanModalPresentationDelegate.default
            presentingViewController.present(panModalPresentable, animated: true, completion: nil)
            //presentingViewController.presentPanModal(panModalPresentable)
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
        }
        
        return viewController
    }

    func switchToTabBar(tab: MainTabBarController.Tab) {
        splitViewController?.contentSplitViewController.currentSupplementaryTab = tab
        
        splitViewController?.compactMainTabBarViewController.selectedIndex = tab.rawValue
        splitViewController?.compactMainTabBarViewController.currentTab = tab
        
        tabBarController.selectedIndex = tab.rawValue
        tabBarController.currentTab = tab
    }
}

private extension SceneCoordinator {
    
    func get(scene: Scene) -> UIViewController? {
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
            let _viewController = MastodonServerRulesViewController()
            _viewController.viewModel = viewModel
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
        case .mastodonResendEmail(let viewModel):
            let _viewController = MastodonResendEmailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonWebView(let viewModel):
            let _viewController = WebViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .searchDetail(let viewModel):
            let _viewController = SearchDetailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .compose(let viewModel):
            let _viewController = ComposeViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .thread(let viewModel):
            let _viewController = ThreadViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .hashtagTimeline(let viewModel):
            let _viewController = HashtagTimelineViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .accountList(let viewModel):
            let _viewController = AccountListViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .profile(let viewModel):
            let _viewController = ProfileViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .bookmark(let viewModel):
            let _viewController = BookmarkViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .followedTags(let viewModel):
            let _viewController = FollowedTagsViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .favorite(let viewModel):
            let _viewController = FavoriteViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .follower(let viewModel):
            let _viewController = FollowerListViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .following(let viewModel):
            let _viewController = FollowingListViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .familiarFollowers(let viewModel):
            let _viewController = FamiliarFollowersViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .rebloggedBy(let viewModel):
            let _viewController = RebloggedByViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .favoritedBy(let viewModel):
            let _viewController = FavoritedByViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .report(let viewModel):
            let _viewController = ReportViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
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
            _viewController.preferredBarTintColor = ThemeService.shared.currentTheme.value.navigationBarBackgroundColor
            _viewController.preferredControlTintColor = Asset.Colors.brand.color
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
        case .settings(let viewModel):
            let _viewController = SettingsViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        }
        
        setupDependency(for: viewController as? NeedsDependency)

        return viewController
    }
    
    private func setupDependency(for needs: NeedsDependency?) {
        needs?.context = appContext
        needs?.coordinator = self
    }
}

//MARK: - MastodonLoginViewControllerDelegate

extension SceneCoordinator: MastodonLoginViewControllerDelegate {
  func backButtonPressed(_ viewController: MastodonLoginViewController) {
    viewController.navigationController?.popViewController(animated: true)
  }

  func nextButtonPressed(_ viewController: MastodonLoginViewController) {
    viewController.login()
  }
}
