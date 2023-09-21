//
//  ViewControllerAnimatedTransitioning.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

protocol ViewControllerAnimatedTransitioningDelegate: AnyObject {
    var wantsInteractiveStart: Bool { get }
    func animationEnded(_ transitionCompleted: Bool)
}

class ViewControllerAnimatedTransitioning: NSObject {

    let operation: UINavigationController.Operation

    var transitionDuration: TimeInterval
    var transitionContext: UIViewControllerContextTransitioning!
    var isInteractive: Bool { return transitionContext.isInteractive }

    weak var delegate: ViewControllerAnimatedTransitioningDelegate?

    init(operation: UINavigationController.Operation) {
        assert(operation != .none)
        self.operation = operation
        self.transitionDuration = 0.3
        super.init()
    }
}

// MARK: - UIViewControllerAnimatedTransitioning
extension ViewControllerAnimatedTransitioning: UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
    }

    func animationEnded(_ transitionCompleted: Bool) {
        delegate?.animationEnded(transitionCompleted)
    }

}

// MARK: - UIViewControllerInteractiveTransitioning
extension ViewControllerAnimatedTransitioning: UIViewControllerInteractiveTransitioning {

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
    }

    var wantsInteractiveStart: Bool {
        return delegate?.wantsInteractiveStart ?? false
    }

}
