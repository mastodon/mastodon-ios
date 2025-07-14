//
//  SearchTransitionController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import UIKit

final class SearchTransitionController: NSObject {

}

// MARK: - UINavigationControllerDelegate
extension SearchTransitionController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push where fromVC is SearchViewController && toVC is SearchDetailViewController:
            return SearchToSearchDetailViewControllerAnimatedTransitioning(operation: operation)
        case .pop where fromVC is SearchDetailViewController && toVC is SearchViewController:
            return SearchToSearchDetailViewControllerAnimatedTransitioning(operation: operation)
        default:
            // fix edge dismiss gesture
            toVC.navigationController?.interactivePopGestureRecognizer?.delegate = nil
            // assertionFailure("Wrong setup. Edge-drag gesture will be invalid. Set delegate to nil when using system push configuration")
            return nil
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        // disable animations when transitioning to/from the profile view controller, since it has a transparent background on the nav bar which makes the transition to standard nav bars look broken
        if viewController is ProfileViewController || navigationController.topViewController is ProfileViewController {
            if let coordinator = navigationController.topViewController?.transitionCoordinator {
                let transparentAppearance = UINavigationBarAppearance()
                transparentAppearance.configureWithTransparentBackground()
                navigationController.navigationBar.standardAppearance = transparentAppearance
                navigationController.navigationBar.compactAppearance = transparentAppearance
                navigationController.navigationBar.scrollEdgeAppearance = transparentAppearance
                coordinator.animate(alongsideTransition: nil) { _ in
                    navigationController.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        switch viewController {
        case is SearchDetailViewController:
            navigationController.interactivePopGestureRecognizer?.isEnabled = false
        default:
            navigationController.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}
