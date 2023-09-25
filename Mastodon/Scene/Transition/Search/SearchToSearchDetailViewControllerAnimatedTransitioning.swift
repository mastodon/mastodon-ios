//
//  SearchToSearchDetailViewControllerAnimatedTransitioning.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-13.
//

import UIKit

final class SearchToSearchDetailViewControllerAnimatedTransitioning: ViewControllerAnimatedTransitioning {

    private var animator: UIViewPropertyAnimator?

    override init(operation: UINavigationController.Operation) {
        super.init(operation: operation)

        self.transitionDuration = 0.2
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
extension SearchToSearchDetailViewControllerAnimatedTransitioning {

    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(using: transitionContext)

        switch operation {
        case .push:     pushTransition(using: transitionContext).startAnimation()
        case .pop:      popTransition(using: transitionContext).startAnimation()
        default:        return
        }
    }

    private func pushTransition(using transitionContext: UIViewControllerContextTransitioning, curve: UIView.AnimationCurve = .easeOut) -> UIViewPropertyAnimator {
        guard let toVC = transitionContext.viewController(forKey: .to) as? SearchDetailViewController,
              let toView = transitionContext.view(forKey: .to) else {
            fatalError()
        }

        let toViewEndFrame = transitionContext.finalFrame(for: toVC)
        transitionContext.containerView.addSubview(toView)
        toView.frame = toViewEndFrame
        toView.setNeedsLayout()
        toView.layoutIfNeeded()
        toVC.searchBar.setNeedsLayout()
        toVC.searchBar.layoutIfNeeded()
        toView.alpha = 0

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), curve: curve)
        animator.addAnimations {
            toView.alpha = 1
        }
        animator.addCompletion { position in
            transitionContext.completeTransition(true)
        }
        return animator
    }

    private func popTransition(using transitionContext: UIViewControllerContextTransitioning, curve: UIView.AnimationCurve = .easeInOut) -> UIViewPropertyAnimator {
        guard let toVC = transitionContext.viewController(forKey: .to) as? SearchViewController,
              let toView = transitionContext.view(forKey: .to) else {
            fatalError()
        }

        let toViewEndFrame = transitionContext.finalFrame(for: toVC)
        transitionContext.containerView.addSubview(toView)
        toView.frame = toViewEndFrame

        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), curve: curve)
        animator.addAnimations {

        }
        animator.addCompletion { position in
            transitionContext.completeTransition(true)
        }
        return animator
    }
}
