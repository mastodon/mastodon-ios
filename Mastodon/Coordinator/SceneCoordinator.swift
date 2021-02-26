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
        case welcome
        case pickServer(viewMode: PickServerViewModel)
        case authentication(viewModel: AuthenticationViewModel)
        case mastodonPinBasedAuthentication(viewModel: MastodonPinBasedAuthenticationViewModel)
        case mastodonRegister(viewModel: MastodonRegisterViewModel)
        case mastodonServerRules(viewModel: MastodonServerRulesViewModel)
        case mastodonConfirmEmail(viewModel: MastodonConfirmEmailViewModel)
        case mastodonResendEmail(viewModel: MastodonResendEmailViewModel)
        
        case alertController(alertController: UIAlertController)
        
        #if DEBUG
        case publicTimeline
        #endif
    }
}

extension SceneCoordinator {
    
    func setup() {
        // Check user authentication status
        
        let request = MastodonAuthentication.sortedFetchRequest
        do {
            let fetchResult = try appContext.managedObjectContext.fetch(request)
            DispatchQueue.main.async {
                var rootViewController: UIViewController
                if fetchResult.isEmpty {
                    let welcomViewController = WelcomeViewController()
                    self.setupDependency(for: welcomViewController)
                    rootViewController = UINavigationController(rootViewController: welcomViewController)
                } else {
                    rootViewController = MainTabBarController(context: self.appContext, coordinator: self)
                }
                self.sceneDelegate.window?.rootViewController = rootViewController
            }
        } catch {
            assertionFailure("CoreDataStack error at app launch!")
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
            let modalNavigationController = UINavigationController(rootViewController: viewController)
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
        case .pickServer(let viewModel):
            let _viewController = PickServerViewController()
            _viewController.viewModel = viewModel
            viewController = _viewController
        case .authentication(let viewModel):
            let _viewController = AuthenticationViewController()
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
        case .alertController(let alertController):
            if let popoverPresentationController = alertController.popoverPresentationController {
                assert(
                    popoverPresentationController.sourceView != nil ||
                    popoverPresentationController.sourceRect != .zero ||
                    popoverPresentationController.barButtonItem != nil
                )
            }
            viewController = alertController
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
