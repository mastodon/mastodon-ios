//
//  MediaPreviewTransitionController.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import UIKit

final class MediaPreviewTransitionController: NSObject {
    
    weak var mediaPreviewViewController: MediaPreviewViewController?
    
    var wantsInteractiveStart = false
    private var panGestureRecognizer: UIPanGestureRecognizer = {
        let gestureRecognizer = UIPanGestureRecognizer()
        gestureRecognizer.maximumNumberOfTouches = 1
        return gestureRecognizer
    }()
    private var dismissInteractiveTransitioning: MediaHostToMediaPreviewViewControllerAnimatedTransitioning?
    
    override init() {
        super.init()
        
        panGestureRecognizer.delegate = self
        panGestureRecognizer.addTarget(self, action: #selector(MediaPreviewTransitionController.panGestureRecognizerHandler(_:)))
    }
    
}

extension MediaPreviewTransitionController {
    
    @objc private func panGestureRecognizerHandler(_ sender: UIPanGestureRecognizer) {
        guard dismissInteractiveTransitioning == nil else { return }
        
        guard let mediaPreviewViewController = self.mediaPreviewViewController else { return }
        wantsInteractiveStart = true
        mediaPreviewViewController.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - UIGestureRecognizerDelegate
extension MediaPreviewTransitionController: UIGestureRecognizerDelegate {

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer || otherGestureRecognizer === panGestureRecognizer {
            // FIXME: should enable zoom up pan dismiss
            return false
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGestureRecognizer {
            guard let mediaPreviewViewController = self.mediaPreviewViewController else { return false }
            return mediaPreviewViewController.isInteractiveDismissible()
        }
        
        return false
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension MediaPreviewTransitionController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let mediaPreviewViewController = presented as? MediaPreviewViewController else {
            assertionFailure()
            return nil
        }
        self.mediaPreviewViewController = mediaPreviewViewController
        self.mediaPreviewViewController?.view.addGestureRecognizer(panGestureRecognizer)
        
        return MediaHostToMediaPreviewViewControllerAnimatedTransitioning(
            operation: .push,
            transitionItem: mediaPreviewViewController.viewModel.transitionItem,
            panGestureRecognizer: panGestureRecognizer
        )
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        // not support interactive present
        return nil
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let mediaPreviewViewController = dismissed as? MediaPreviewViewController else {
            assertionFailure()
            return nil
        }

        return MediaHostToMediaPreviewViewControllerAnimatedTransitioning(
            operation: .pop,
            transitionItem: mediaPreviewViewController.viewModel.transitionItem,
            panGestureRecognizer: panGestureRecognizer
        )
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let transitioning = animator as? MediaHostToMediaPreviewViewControllerAnimatedTransitioning,
        transitioning.operation == .pop, wantsInteractiveStart else {
            return nil
        }

        dismissInteractiveTransitioning = transitioning
        transitioning.delegate = self
        return transitioning
    }
    
}

// MARK: - ViewControllerAnimatedTransitioningDelegate
extension MediaPreviewTransitionController: ViewControllerAnimatedTransitioningDelegate {

    func animationEnded(_ transitionCompleted: Bool) {
        dismissInteractiveTransitioning = nil
        wantsInteractiveStart = false
    }

}
