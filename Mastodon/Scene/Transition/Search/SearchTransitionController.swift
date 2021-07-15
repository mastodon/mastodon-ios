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
}
