//
//  MediaHostToMediaPreviewViewControllerAnimatedTransitioning.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

import os.log
import UIKit
import func AVFoundation.AVMakeRect

final class MediaHostToMediaPreviewViewControllerAnimatedTransitioning: ViewControllerAnimatedTransitioning {
    
    let transitionItem: MediaPreviewTransitionItem
    let panGestureRecognizer: UIPanGestureRecognizer

    private var isTransitionContextFinish = false
    
    private var popInteractiveTransitionAnimator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)
    private var itemInteractiveTransitionAnimator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)

    init(operation: UINavigationController.Operation, transitionItem: MediaPreviewTransitionItem, panGestureRecognizer: UIPanGestureRecognizer) {
        self.transitionItem = transitionItem
        self.panGestureRecognizer = panGestureRecognizer
        super.init(operation: operation)
    }
    
    class func animator(initialVelocity: CGVector = .zero) -> UIViewPropertyAnimator {
        let timingParameters = UISpringTimingParameters(mass: 4.0, stiffness: 1300, damping: 180, initialVelocity: initialVelocity)
        return UIViewPropertyAnimator(duration: 0.5, timingParameters: timingParameters)
    }
    
}

// MARK: - UIViewControllerAnimatedTransitioning
extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {
    
    override func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        super.animateTransition(using: transitionContext)
        
        switch operation {
        case .push:     pushTransition(using: transitionContext).startAnimation()
        case .pop:      popTransition(using: transitionContext).startAnimation()
        default:        return
        }
    }
    
    private func pushTransition(using transitionContext: UIViewControllerContextTransitioning, curve: UIView.AnimationCurve = .easeInOut) -> UIViewPropertyAnimator {
        guard let toVC = transitionContext.viewController(forKey: .to) as? MediaPreviewViewController,
              let toView = transitionContext.view(forKey: .to) else {
            fatalError()
        }

        let toViewEndFrame = transitionContext.finalFrame(for: toVC)
        toView.frame = toViewEndFrame
        toView.alpha = 0
        transitionContext.containerView.addSubview(toView)
        // set to image hidden
        toVC.pagingViewConttroller.view.alpha = 0
        // set from image hidden. update hidden when paging. seealso: `MediaPreviewViewController`
        transitionItem.source.updateAppearance(position: .start, index: toVC.viewModel.currentPage.value)
        
        // Set transition image view
        assert(transitionItem.initialFrame != nil)
        let initialFrame = transitionItem.initialFrame ?? toViewEndFrame
        let transitionTargetFrame: CGRect = {
            let aspectRatio = transitionItem.aspectRatio ?? CGSize(width: initialFrame.width, height: initialFrame.height)
            return AVMakeRect(aspectRatio: aspectRatio, insideRect: toView.bounds)
        }()
        let transitionImageView: UIImageView = {
            let imageView = UIImageView(frame: transitionContext.containerView.convert(initialFrame, from: nil))
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = false
            imageView.image = transitionItem.image
            return imageView
        }()
        transitionItem.targetFrame = transitionTargetFrame
        transitionItem.imageView = transitionImageView
        transitionContext.containerView.addSubview(transitionImageView)
        
        let animator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)

        animator.addAnimations {
            transitionImageView.frame = transitionTargetFrame
            toView.alpha = 1
        }

        animator.addCompletion { position in
            toVC.pagingViewConttroller.view.alpha = 1
            transitionImageView.removeFromSuperview()
            transitionContext.completeTransition(position == .end)
        }

        return animator
    }
    
    private func popTransition(using transitionContext: UIViewControllerContextTransitioning, curve: UIView.AnimationCurve = .easeInOut) -> UIViewPropertyAnimator {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? MediaPreviewViewController,
              let fromView = transitionContext.view(forKey: .from),
              let mediaPreviewImageViewController = fromVC.pagingViewConttroller.currentViewController as? MediaPreviewImageViewController,
              let index = fromVC.pagingViewConttroller.currentIndex else {
            fatalError()
        }
        
        // assert view hierarchy not change
        let toVC = transitionItem.previewableViewController
        let targetFrame = toVC.sourceFrame(transitionItem: transitionItem, index: index)
        
        let imageView = mediaPreviewImageViewController.previewImageView.imageView
        let _snapshot: UIView? = {
            transitionItem.snapshotRaw = imageView
            let snapshot = imageView.snapshotView(afterScreenUpdates: false)
            snapshot?.clipsToBounds = true
            snapshot?.contentMode = .scaleAspectFill
            return snapshot
        }()
        guard let snapshot = _snapshot else {
            transitionContext.completeTransition(false)
            fatalError()
        }
        mediaPreviewImageViewController.view.insertSubview(snapshot, aboveSubview: mediaPreviewImageViewController.previewImageView)
                    
        snapshot.center = transitionContext.containerView.center

        transitionItem.imageView = imageView
        transitionItem.snapshotTransitioning = snapshot
        transitionItem.initialFrame = snapshot.frame
        transitionItem.targetFrame = targetFrame

        // disable interaction
        fromVC.pagingViewConttroller.isUserInteractionEnabled = false
        
        let animator = popInteractiveTransitionAnimator

        self.transitionItem.snapshotRaw?.alpha = 0.0
        animator.addAnimations {
            if let targetFrame = targetFrame {
                self.transitionItem.snapshotTransitioning?.frame = targetFrame
            } else {
                fromView.alpha = 0
            }
            self.transitionItem.sourceImageViewCornerRadius.flatMap { self.transitionItem.snapshotTransitioning?.layer.cornerRadius = $0 }
            fromVC.closeButtonBackground.alpha = 0
            fromVC.visualEffectView.effect = nil
        }

        animator.addCompletion { position in
            self.transitionItem.snapshotTransitioning?.removeFromSuperview()
            self.transitionItem.source.updateAppearance(position: position, index: nil)
            transitionContext.completeTransition(position == .end)
        }

        return animator
    }
    
}

// MARK: - UIViewControllerInteractiveTransitioning
extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {
    
    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
     
        switch operation {
        case .pop:
            // Note: change item.imageView transform via pan gesture
            panGestureRecognizer.addTarget(self, action: #selector(MediaHostToMediaPreviewViewControllerAnimatedTransitioning.updatePanGestureInteractive(_:)))
            popInteractiveTransition(using: transitionContext)
        default:
            assertionFailure()
            return
        }
    }
    
    private func popInteractiveTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from) as? MediaPreviewViewController,
              let fromView = transitionContext.view(forKey: .from),
              let mediaPreviewImageViewController = fromVC.pagingViewConttroller.currentViewController as? MediaPreviewImageViewController,
                    let index = fromVC.pagingViewConttroller.currentIndex else {
            fatalError()
        }
        
        // assert view hierarchy not change
        let toVC = transitionItem.previewableViewController
        let targetFrame = toVC.sourceFrame(transitionItem: transitionItem, index: index)
        
        let imageView = mediaPreviewImageViewController.previewImageView.imageView
        let _snapshot: UIView? = {
            transitionItem.snapshotRaw = imageView
            let snapshot = imageView.snapshotView(afterScreenUpdates: false)
            snapshot?.clipsToBounds = true
            snapshot?.contentMode = .scaleAspectFill
            return snapshot
        }()
        guard let snapshot = _snapshot else {
            transitionContext.completeTransition(false)
            return
        }
        mediaPreviewImageViewController.view.insertSubview(snapshot, aboveSubview: mediaPreviewImageViewController.previewImageView)
                    
        snapshot.center = transitionContext.containerView.center

        transitionItem.imageView = imageView
        transitionItem.snapshotTransitioning = snapshot
        transitionItem.initialFrame = snapshot.frame
        transitionItem.targetFrame = targetFrame ?? snapshot.frame

        // disable interaction
        fromVC.pagingViewConttroller.isUserInteractionEnabled = false
        
        let animator = popInteractiveTransitionAnimator

        let blurEffect = fromVC.visualEffectView.effect
        self.transitionItem.snapshotRaw?.alpha = 0.0
        
        animator.addAnimations {
            switch self.transitionItem.source {
            case .profileBanner:
                self.transitionItem.snapshotTransitioning?.alpha = 0.4
            default:
                break
            }
            fromVC.closeButtonBackground.alpha = 0
            fromVC.visualEffectView.effect = nil
            self.transitionItem.sourceImageViewCornerRadius.flatMap { self.transitionItem.snapshotTransitioning?.layer.cornerRadius = $0 }
        }

        animator.addCompletion { position in
            fromVC.pagingViewConttroller.isUserInteractionEnabled = true
            fromVC.closeButtonBackground.alpha = position == .end ? 0 : 1
            self.transitionItem.imageView?.isHidden = position == .end
            self.transitionItem.snapshotRaw?.alpha = position == .start ? 1.0 : 0.0
            self.transitionItem.snapshotTransitioning?.removeFromSuperview()
            if position == .end {
                // reset appearance
                self.transitionItem.source.updateAppearance(position: position, index: nil)
            }
            fromVC.visualEffectView.effect = position == .end ? nil : blurEffect
            transitionContext.completeTransition(position == .end)
        }
    }
    
}

extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {
    
    @objc func updatePanGestureInteractive(_ sender: UIPanGestureRecognizer) {
        guard !isTransitionContextFinish else { return }    // do not accept transition abort

        switch sender.state {
        case .began, .changed:
            let translation = sender.translation(in: transitionContext.containerView)
            let percent = popInteractiveTransitionAnimator.fractionComplete + progressStep(for: translation)
            popInteractiveTransitionAnimator.fractionComplete = percent
            transitionContext.updateInteractiveTransition(percent)
            updateTransitionItemPosition(of: translation)

            // Reset translation to zero
            sender.setTranslation(CGPoint.zero, in: transitionContext.containerView)
        case .ended, .cancelled:
            let targetPosition = completionPosition()
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: target position: %s", ((#file as NSString).lastPathComponent), #line, #function, targetPosition == .end ? "end" : "start")
            isTransitionContextFinish = true
            animate(targetPosition)

            targetPosition == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
        default:
            return
        }
    }

    private func convert(_ velocity: CGPoint, for item: MediaPreviewTransitionItem?) -> CGVector {
        guard let currentFrame = item?.imageView?.frame, let targetFrame = item?.targetFrame else {
            return CGVector.zero
        }

        let dx = abs(targetFrame.midX - currentFrame.midX)
        let dy = abs(targetFrame.midY - currentFrame.midY)

        guard dx > 0.0 && dy > 0.0 else {
            return CGVector.zero
        }

        let range = CGFloat(35.0)
        let clippedVx = clip(-range, range, velocity.x / dx)
        let clippedVy = clip(-range, range, velocity.y / dy)
        return CGVector(dx: clippedVx, dy: clippedVy)
    }

    private func completionPosition() -> UIViewAnimatingPosition {
        let completionThreshold: CGFloat = 0.33
        let flickMagnitude: CGFloat = 1200 // pts/sec
        let velocity = panGestureRecognizer.velocity(in: transitionContext.containerView).vector
        let isFlick = (velocity.magnitude > flickMagnitude)
        let isFlickDown = isFlick && (velocity.dy > 0.0)
        let isFlickUp = isFlick && (velocity.dy < 0.0)

        if (operation == .push && isFlickUp) || (operation == .pop && isFlickDown) {
            return .end
        } else if (operation == .push && isFlickDown) || (operation == .pop && isFlickUp) {
            return .start
        } else if popInteractiveTransitionAnimator.fractionComplete > completionThreshold {
            return .end
        } else {
            return .start
        }
    }

    // Create item animator and start it
    func animate(_ toPosition: UIViewAnimatingPosition) {
        // Create a property animator to animate each image's frame change
        let gestureVelocity = panGestureRecognizer.velocity(in: transitionContext.containerView)
        let velocity = convert(gestureVelocity, for: transitionItem)
        let itemAnimator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: velocity)

        itemAnimator.addAnimations {
            if toPosition == .end {
                switch self.transitionItem.source {
                case .profileBanner where toPosition == .end:
                    // fade transition for banner
                    self.transitionItem.snapshotTransitioning?.alpha = 0
                default:
                    if let targetFrame = self.transitionItem.targetFrame {
                        self.transitionItem.snapshotTransitioning?.frame = targetFrame
                    } else {
                        self.transitionItem.snapshotTransitioning?.alpha = 0
                    }
                }
                
            } else {
                if let initialFrame = self.transitionItem.initialFrame {
                    self.transitionItem.snapshotTransitioning?.frame = initialFrame
                } else {
                    self.transitionItem.snapshotTransitioning?.alpha = 1
                }
            }
        }

        // Start the property animator and keep track of it
        self.itemInteractiveTransitionAnimator = itemAnimator
        itemAnimator.startAnimation()

        // Reverse the transition animator if we are returning to the start position
        popInteractiveTransitionAnimator.isReversed = (toPosition == .start)

        if popInteractiveTransitionAnimator.state == .inactive {
            popInteractiveTransitionAnimator.startAnimation()
        } else {
            let durationFactor = CGFloat(itemAnimator.duration / popInteractiveTransitionAnimator.duration)
            popInteractiveTransitionAnimator.continueAnimation(withTimingParameters: nil, durationFactor: durationFactor)
        }
    }

    private func progressStep(for translation: CGPoint) -> CGFloat {
        return (operation == .push ? -1.0 : 1.0) * translation.y / transitionContext.containerView.bounds.midY
    }

    private func updateTransitionItemPosition(of translation: CGPoint) {
        let progress = progressStep(for: translation)

        let initialSize = transitionItem.initialFrame!.size
        guard initialSize != .zero else { return }
        // assert(initialSize != .zero)

        guard let snapshot = transitionItem.snapshotTransitioning,
        let finalSize = transitionItem.targetFrame?.size else {
            return
        }

        if snapshot.frame.size == .zero {
            snapshot.frame.size = initialSize
        }

        let currentSize = snapshot.frame.size

        let itemPercentComplete = clip(-0.05, 1.05, (currentSize.width - initialSize.width) / (finalSize.width - initialSize.width) + progress)
        let itemWidth = lerp(initialSize.width, finalSize.width, itemPercentComplete)
        let itemHeight = lerp(initialSize.height, finalSize.height, itemPercentComplete)
        assert(currentSize.width != 0.0)
        assert(currentSize.height != 0.0)
        let scaleTransform = CGAffineTransform(scaleX: (itemWidth / currentSize.width), y: (itemHeight / currentSize.height))
        let scaledOffset = transitionItem.touchOffset.apply(transform: scaleTransform)

        snapshot.center = (snapshot.center + (translation + (transitionItem.touchOffset - scaledOffset))).point
        snapshot.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: itemWidth, height: itemHeight))
        transitionItem.touchOffset = scaledOffset
    }
    
}

