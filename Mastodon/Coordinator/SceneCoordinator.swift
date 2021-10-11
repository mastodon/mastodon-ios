//
//  SceneCoordinator.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.

import UIKit
import SafariServices
import CoreDataStack
import PanModal

final public class SceneCoordinator {
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    private weak var appContext: AppContext!
    
    let id = UUID().uuidString
    
    private(set) weak var tabBarController: MainTabBarController!
    private(set) weak var splitViewController: RootSplitViewController?
    
    private(set) var secondaryStackHashValues = Set<Int>()
    
    init(scene: UIScene, sceneDelegate: SceneDelegate, appContext: AppContext) {
        self.scene = scene
        self.sceneDelegate = sceneDelegate
        self.appContext = appContext
        
        scene.session.sceneCoordinator = self
    }
}

extension SceneCoordinator {
    enum Transition {
        case show                           // push
        case showDetail                     // replace
        case modal(animated: Bool, completion: (() -> Void)? = nil)
        case panModal
        case custom(transitioningDelegate: UIViewControllerTransitioningDelegate)
        case customPush
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
        case mastodonWebView(viewModel:WebViewModel)
        
        #if ASDK
        // ASDK
        case asyncHome
        #endif

        // search
        case searchDetail(viewModel: SearchDetailViewModel)

        // compose
        case compose(viewModel: ComposeViewModel)
        
        // thread
        case thread(viewModel: ThreadViewModel)
        
        // Hashtag Timeline
        case hashtagTimeline(viewModel: HashtagTimelineViewModel)
      
        // profile
        case accountList
        case profile(viewModel: ProfileViewModel)
        case favorite(viewModel: FavoriteViewModel)

        // setting
        case settings(viewModel: SettingsViewModel)
        
        // report
        case report(viewModel: ReportViewModel)

        // suggestion account
        case suggestionAccount(viewModel: SuggestionAccountViewModel)
        
        // media preview
        case mediaPreview(viewModel: MediaPreviewViewModel)
        
        // misc
        case safari(url: URL)
        case alertController(alertController: UIAlertController)
        case activityViewController(activityViewController: UIActivityViewController, sourceView: UIView?, barButtonItem: UIBarButtonItem?)
        
        #if DEBUG
        case publicTimeline
        #endif
        
        var isOnboarding: Bool {
            switch self {
            case .welcome,
                 .mastodonPickServer,
                 .mastodonRegister,
                 .mastodonServerRules,
                 .mastodonConfirmEmail,
                 .mastodonResendEmail:
                return true
            default:
                return false
            }
        }
    }
}

extension SceneCoordinator {
    
    func setup() {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            let viewController = MainTabBarController(context: appContext, coordinator: self)
            sceneDelegate.window?.rootViewController = viewController
            tabBarController = viewController
        default:
            let splitViewController = RootSplitViewController(context: appContext, coordinator: self)
            self.splitViewController = splitViewController
            self.tabBarController = splitViewController.mainTabBarController
            sceneDelegate.window?.rootViewController = splitViewController
        }
    }
    
    func setupOnboardingIfNeeds(animated: Bool) {
        // Check user authentication status and show onboarding if needs
        do {
            let request = MastodonAuthentication.sortedFetchRequest
            if try appContext.managedObjectContext.count(for: request) == 0 {
                DispatchQueue.main.async {
                    self.present(
                        scene: .welcome,
                        from: nil,
                        transition: .modal(animated: animated, completion: nil)
                    )
                }
            }
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
    
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
            if let splitViewController = splitViewController, !splitViewController.isCollapsed,
               let supplementaryViewController = splitViewController.viewController(for: .supplementary) as? UINavigationController,
               (supplementaryViewController === presentingViewController || supplementaryViewController.viewControllers.contains(presentingViewController)) ||
                (presentingViewController is UserTimelineViewController && presentingViewController.view.isDescendant(of: supplementaryViewController.view))
            {
                fallthrough
            } else {
                if secondaryStackHashValues.contains(presentingViewController.hashValue) {
                    secondaryStackHashValues.insert(viewController.hashValue)
                }
                presentingViewController.show(viewController, sender: sender)
            }
        case .showDetail:
            secondaryStackHashValues.insert(viewController.hashValue)
            let navigationController = AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
            presentingViewController.showDetailViewController(navigationController, sender: sender)
            
        case .modal(let animated, let completion):
            let modalNavigationController: UINavigationController = {
                if scene.isOnboarding {
                    return AdaptiveStatusBarStyleNavigationController(rootViewController: viewController)
                } else {
                    return UINavigationController(rootViewController: viewController)
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

        case .custom(let transitioningDelegate):
            viewController.modalPresentationStyle = .custom
            viewController.transitioningDelegate = transitioningDelegate
            (splitViewController ?? presentingViewController)?.present(viewController, animated: true, completion: nil)
            
        case .customPush:
            // set delegate in view controller
            assert(sender?.navigationController?.delegate != nil)
            sender?.navigationController?.pushViewController(viewController, animated: true)
            
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
        tabBarController.currentTab.value = tab
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
        case .mastodonResendEmail(let viewModel):
            let _viewController = MastodonResendEmailViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .mastodonWebView(let viewModel):
            let _viewController = WebViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        #if ASDK
        case .asyncHome:
            let _viewController = AsyncHomeTimelineViewController()
            viewController = _viewController
        #endif
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
        case .accountList:
            let _viewController = AccountListViewController()
            viewController = _viewController
        case .profile(let viewModel):
            let _viewController = ProfileViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .favorite(let viewModel):
            let _viewController = FavoriteViewController()
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
            _viewController.preferredControlTintColor = Asset.Colors.brandBlue.color
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
        case .report(let viewModel):
            let _viewController = ReportViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        #if DEBUG
        case .publicTimeline:
            let _viewController = PublicTimelineViewController()
            _viewController.viewModel = PublicTimelineViewModel(context: appContext)
            viewController = _viewController
        #endif
        }
        
        setupDependency(for: viewController as? NeedsDependency)

        return viewController
    }
    
    private func setupDependency(for needs: NeedsDependency?) {
        needs?.context = appContext
        needs?.coordinator = self
    }
    
}
