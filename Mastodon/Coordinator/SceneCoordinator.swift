//
//  SceneCoordinator.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-1-27.

import UIKit
import SafariServices
import CoreDataStack

final public class SceneCoordinator {
    
    private weak var scene: UIScene!
    private weak var sceneDelegate: SceneDelegate!
    private weak var appContext: AppContext!
    
    let id = UUID().uuidString
    
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
        case custom(transitioningDelegate: UIViewControllerTransitioningDelegate)
        case customPush
        case safariPresent(animated: Bool, completion: (() -> Void)? = nil)
        case activityViewControllerPresent(animated: Bool, completion: (() -> Void)? = nil)
        case alertController(animated: Bool, completion: (() -> Void)? = nil)
    }
    
    enum Scene {
        // onboarding
        case welcome
        case mastodonPickServer(viewMode: MastodonPickServerViewModel)
        case mastodonPinBasedAuthentication(viewModel: MastodonPinBasedAuthenticationViewModel)
        case mastodonRegister(viewModel: MastodonRegisterViewModel)
        case mastodonServerRules(viewModel: MastodonServerRulesViewModel)
        case mastodonConfirmEmail(viewModel: MastodonConfirmEmailViewModel)
        case mastodonResendEmail(viewModel: MastodonResendEmailViewModel)
        
        // compose
        case compose(viewModel: ComposeViewModel)
        
        // Hashtag Timeline
        case hashtagTimeline(viewModel: HashtagTimelineViewModel)
        
        // misc
        case alertController(alertController: UIAlertController)
        
        #if DEBUG
        case publicTimeline
        #endif
        
        var isOnboarding: Bool {
            switch self {
            case .welcome,
                 .mastodonPickServer,
                 .mastodonPinBasedAuthentication,
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
        let viewController = MainTabBarController(context: appContext, coordinator: self)
        sceneDelegate.window?.rootViewController = viewController
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
        
        if let mainTabBarController = presentingViewController as? MainTabBarController,
           let navigationController = mainTabBarController.selectedViewController as? UINavigationController,
           let topViewController = navigationController.topViewController {
            presentingViewController = topViewController
        }
        
        switch transition {
        case .show:
            presentingViewController.show(viewController, sender: sender)
            
        case .showDetail:
            let navigationController = UINavigationController(rootViewController: viewController)
            presentingViewController.showDetailViewController(navigationController, sender: sender)
            
        case .modal(let animated, let completion):
            let modalNavigationController: UINavigationController = {
                if scene.isOnboarding {
                    return DarkContentStatusBarStyleNavigationController(rootViewController: viewController)
                } else {
                    return UINavigationController(rootViewController: viewController)
                }
            }()
            if let adaptivePresentationControllerDelegate = viewController as? UIAdaptivePresentationControllerDelegate {
                modalNavigationController.presentationController?.delegate = adaptivePresentationControllerDelegate
            }
            presentingViewController.present(modalNavigationController, animated: animated, completion: completion)
            
        case .custom(let transitioningDelegate):
            viewController.modalPresentationStyle = .custom
            viewController.transitioningDelegate = transitioningDelegate
            sender?.present(viewController, animated: true, completion: nil)
            
        case .customPush:
            // set delegate in view controller
            assert(sender?.navigationController?.delegate != nil)
            sender?.navigationController?.pushViewController(viewController, animated: true)
            
        case .safariPresent(let animated, let completion):
            presentingViewController.present(viewController, animated: animated, completion: completion)
            
        case .activityViewControllerPresent(let animated, let completion):
            presentingViewController.present(viewController, animated: animated, completion: completion)
            
        case .alertController(let animated, let completion):
            presentingViewController.present(viewController, animated: animated, completion: completion)
        }
        
        return viewController
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
        case .mastodonPinBasedAuthentication(let viewModel):
            let _viewController = MastodonPinBasedAuthenticationViewController()
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
        case .compose(let viewModel):
            let _viewController = ComposeViewController()
            _viewController.viewModel = viewModel
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
        case .hashtagTimeline(let viewModel):
            let _viewController = HashtagTimelineViewController()
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
