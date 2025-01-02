//
//  MediaHostToMediaPreviewViewControllerAnimatedTransitioning.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-28.
//

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
        toVC.pagingViewController.view.alpha = 0
        // set from image hidden. update hidden when paging. seealso: `MediaPreviewViewController`
        transitionItem.source.updateAppearance(position: .start, index: toVC.viewModel.currentPage)
        
        // Set transition image view
        assert(transitionItem.initialFrame != nil)
        let initialContainerFrame = transitionItem.initialContainerFrame ?? toViewEndFrame
        let initialFrame = transitionItem.initialFrame ?? toViewEndFrame
        
        let transitionTargetFrame: CGRect = {
            let aspectRatio = transitionItem.aspectRatio ?? CGSize(width: initialContainerFrame.width, height: initialContainerFrame.height)
            return AVMakeRect(aspectRatio: aspectRatio, insideRect: toView.bounds.inset(by: toView.safeAreaInsets))
        }()
        
        // We need an additional clipping container because the image origin can be shifted with the focus point
        let transitionContainer: UIView = {
            let view = UIView(frame: transitionContext.containerView.convert(initialContainerFrame, from: nil))
            view.clipsToBounds = true
            return view
        }()
        let transitionImageView: UIImageView = {
            let imageView = UIImageView(frame: initialFrame)
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            imageView.isUserInteractionEnabled = false
            imageView.image = transitionItem.image
            // accessibility
            imageView.accessibilityIgnoresInvertColors = true
            return imageView
        }()
        transitionContainer.addSubview(transitionImageView)
        transitionContext.containerView.addSubview(transitionContainer)
        transitionItem.targetFrame = transitionTargetFrame
        transitionItem.transitionView = transitionContainer
        
        toVC.topToolbar.alpha = 0

        if UIAccessibility.isReduceTransparencyEnabled {
            toVC.visualEffectView.alpha = 0
        }

        let animator = MediaHostToMediaPreviewViewControllerAnimatedTransitioning.animator(initialVelocity: .zero)

        animator.addAnimations {
            transitionContainer.frame = transitionTargetFrame
            transitionImageView.frame = CGRect(origin: .zero, size: transitionTargetFrame.size)
            toView.alpha = 1
            if UIAccessibility.isReduceTransparencyEnabled {
                toVC.visualEffectView.alpha = 1
            }
        }

        animator.addCompletion { position in
            toVC.pagingViewController.view.alpha = 1
            transitionContainer.removeFromSuperview()
            UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut]) {
                toVC.topToolbar.alpha = 1
            }
            transitionContext.completeTransition(position == .end)
        }

        return animator
    }
    
    @discardableResult
    private func popTransition(
        using transitionContext: UIViewControllerContextTransitioning,
        curve: UIView.AnimationCurve = .easeInOut
    ) -> UIViewPropertyAnimator {
        let animator = popInteractiveTransitionAnimator
        
        animator.addCompletion { position in
            transitionContext.completeTransition(position == .end)
        }
        
        guard let fromVC = transitionContext.viewController(forKey: .from) as? MediaPreviewViewController,
              let index = fromVC.pagingViewController.currentIndex,
              let fromView = transitionContext.view(forKey: .from),
              let mediaPreviewTransitionViewController = fromVC.pagingViewController.currentViewController as? MediaPreviewTransitionViewController,
              let mediaPreviewTransitionContext = mediaPreviewTransitionViewController.mediaPreviewTransitionContext
        else {
            animator.addAnimations {
                self.transitionItem.source.updateAppearance(position: .end, index: nil)
            }
            return animator
        }

        if let toVC = transitionContext.viewController(forKey: .to) {
            animator.addCompletion { _ in
                toVC.setNeedsStatusBarAppearanceUpdate()
            }
        }
        
        // update top toolbar
        UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut]) {
            fromVC.topToolbar.alpha = 0
        }
        animator.addCompletion { position in
            UIView.animate(withDuration: 0.33, delay: 0, options: [.curveEaseInOut]) {
                fromVC.topToolbar.alpha = position == .end ? 0 : 1
            }
        }
        
        // update view controller
        fromVC.pagingViewController.isUserInteractionEnabled = false
        animator.addCompletion { position in
            fromVC.pagingViewController.isUserInteractionEnabled = true
        }
        
        // update background
        let blurEffect = fromVC.visualEffectView.effect
        animator.addAnimations {
            fromVC.visualEffectView.effect = nil
            if UIAccessibility.isReduceTransparencyEnabled {
                fromVC.visualEffectView.alpha = 0
            }
        }
        animator.addCompletion { position in
            fromVC.visualEffectView.effect = position == .end ? nil : blurEffect
            if UIAccessibility.isReduceTransparencyEnabled {
                fromVC.visualEffectView.alpha = position == .end ? 0 : 1
            }
        }
        
        // update transition item source
        animator.addCompletion { position in
            if position == .end {
                // reset appearance
                self.transitionItem.source.updateAppearance(position: position, index: nil)
            }
        }
        
        // update transitioning snapshot
        let transitionMaskView = UIView(frame: transitionContext.containerView.bounds)
        transitionMaskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        transitionContext.containerView.addSubview(transitionMaskView)
        transitionItem.interactiveTransitionMaskView = transitionMaskView
        
        animator.addCompletion { position in
            transitionMaskView.removeFromSuperview()
        }
        
        let transitionMaskViewTapGestureRecognizer = UITapGestureRecognizer.singleTapGestureRecognizer
        transitionMaskViewTapGestureRecognizer.addTarget(self, action: #selector(MediaHostToMediaPreviewViewControllerAnimatedTransitioning.transitionMaskViewTapGestureRecognizerHandler(_:)))
        transitionMaskView.addGestureRecognizer(transitionMaskViewTapGestureRecognizer)
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = transitionMaskView.bounds
        maskLayer.path = UIBezierPath(rect: maskLayer.bounds).cgPath
        transitionMaskView.layer.mask = maskLayer
        transitionItem.interactiveTransitionMaskLayer = maskLayer
    
        mediaPreviewTransitionContext.snapshot.contentMode = .scaleAspectFill
        mediaPreviewTransitionContext.snapshot.clipsToBounds = true

        let transitionContainerView = UIView(frame: .zero)
        transitionContainerView.frame.size = mediaPreviewTransitionContext.snapshot.frame.size
        transitionContainerView.center = transitionMaskView.center
        transitionContainerView.clipsToBounds = true

        // attach transitioning snapshot
        transitionContainerView.addSubview(mediaPreviewTransitionContext.snapshot)
        transitionMaskView.addSubview(transitionContainerView)
        fromVC.view.bringSubviewToFront(fromVC.topToolbar)

        transitionItem.transitionView = mediaPreviewTransitionContext.transitionView
        transitionItem.snapshotTransitioning = mediaPreviewTransitionContext.snapshot
        transitionItem.initialContainerFrame = transitionContainerView.frame
        transitionItem.initialFrame = mediaPreviewTransitionContext.snapshot.frame
        transitionItem.containerSnapshotTransitioning = transitionContainerView

        // assert view hierarchy not change
        let toVC = transitionItem.previewableViewController
        let targetFramesProvider = toVC.sourceFrame(transitionItem: transitionItem, index: index)
        let containerTargetFrame = targetFramesProvider?.containerSourceFrame
        let targetFrame = targetFramesProvider?.contentSourceFrame
        transitionItem.containerTargetFrame = containerTargetFrame
        transitionItem.targetFrame = targetFrame
        
        animator.addAnimations {
            self.transitionItem.snapshotTransitioning?.layer.cornerRadius = self.transitionItem.sourceImageViewCornerRadius ?? 0
        }
        animator.addCompletion { position in
            self.transitionItem.snapshotTransitioning?.layer.cornerRadius = position == .end ? 0 : (self.transitionItem.sourceImageViewCornerRadius ?? 0)
        }
        
        if !isInteractive {
            animator.addAnimations {
                if let containerTargetFrame {
                    switch self.transitionItem.source {
                    case .profileBanner:
                        fromView.alpha = 0
                        self.transitionItem.snapshotTransitioning?.alpha = 0
                    default:
                        self.transitionItem.containerSnapshotTransitioning?.frame = containerTargetFrame
                        if let targetFrame {
                            self.transitionItem.snapshotTransitioning?.frame = targetFrame
                        } else {
                            self.transitionItem.snapshotTransitioning?.frame.size = containerTargetFrame.size
                        }
                    }
                } else {
                    fromView.alpha = 0
                }
            }
            
            // calculate transition mask
            let maskLayerToRect: CGRect? = {
                guard case .attachments = transitionItem.source else { return nil }
                guard let navigationBar = toVC.navigationController?.navigationBar, let navigationBarSuperView = navigationBar.superview else { return nil }
                let navigationBarFrameInWindow = navigationBarSuperView.convert(navigationBar.frame, to: nil)
                
                // crop rect top edge
                var rect = transitionMaskView.frame
                let _toViewFrameInWindow = toVC.view.superview.flatMap { $0.convert(toVC.view.frame, to: nil) }
                if let toViewFrameInWindow = _toViewFrameInWindow, toViewFrameInWindow.minY > navigationBarFrameInWindow.maxY {
                    rect.origin.y = toViewFrameInWindow.minY
                } else {
                    rect.origin.y = navigationBarFrameInWindow.maxY + UIView.separatorLineHeight(of: toVC.view)     // extra hairline
                }
                
                return rect
            }()
            let maskLayerToPath = maskLayerToRect.flatMap { UIBezierPath(rect: $0) }?.cgPath
            
            if let maskLayerToPath = maskLayerToPath {
                maskLayer.path = maskLayerToPath
            }
        }
        
        mediaPreviewTransitionContext.transitionView.isHidden = true
        animator.addCompletion { position in
            self.transitionItem.transitionView?.isHidden = position == .end
            self.transitionItem.snapshotRaw?.alpha = position == .start ? 1.0 : 0.0
            self.transitionItem.containerSnapshotTransitioning?.removeFromSuperview()
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
        popTransition(using: transitionContext)
    }
    
}

extension MediaHostToMediaPreviewViewControllerAnimatedTransitioning {

    // app may freeze without response during transitioning
    // patch it by tap the view to finish transitioning 
    @objc func transitionMaskViewTapGestureRecognizerHandler(_ sender: UITapGestureRecognizer) {
        // not panning now but still in transitioning
        guard panGestureRecognizer.state == .possible,
              transitionContext.isAnimated, transitionContext.isInteractive else {
            return
        }

        // finish or cancel current transitioning
        let targetPosition = completionPosition()
        isTransitionContextFinish = true
        animate(targetPosition)

        targetPosition == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
    }
    
    @objc func updatePanGestureInteractive(_ sender: UIPanGestureRecognizer) {
        guard !isTransitionContextFinish else {
            return
        }    // do not accept transition abort

        switch sender.state {
        case .possible:
            return
        case .began, .changed:
            let translation = sender.translation(in: transitionContext.containerView)
            let percent = progressStep(for: translation)
            popInteractiveTransitionAnimator.fractionComplete = percent
            transitionContext.updateInteractiveTransition(percent)
            updateTransitionItemPosition(of: translation)
        case .ended, .cancelled:
            let targetPosition = completionPosition()
            isTransitionContextFinish = true
            animate(targetPosition)

            targetPosition == .end ? transitionContext.finishInteractiveTransition() : transitionContext.cancelInteractiveTransition()
        case .failed:
            return
        @unknown default:
            assertionFailure()
            return
        }
    }

    private func convert(_ velocity: CGPoint, for item: MediaPreviewTransitionItem?) -> CGVector {
        guard let currentFrame = item?.transitionView?.frame,
              let targetFrame = item?.targetFrame
        else {
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

        if (operation == .push && isFlickUp) || (operation == .pop && (isFlickDown || isFlickUp)) {
            return .end
        } else if (operation == .push && isFlickDown) {
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
        
        var maskLayerToFinalPath: CGPath?
        if toPosition == .end,
           let transitionMaskView = transitionItem.interactiveTransitionMaskView,
           let snapshot = transitionItem.containerSnapshotTransitioning {
            let toVC = transitionItem.previewableViewController
            
            var needsMaskWithAnimation = true
            let maskLayerToRect: CGRect? = {
                guard case .attachments = transitionItem.source else { return nil }
                guard let navigationBar = toVC.navigationController?.navigationBar, let navigationBarSuperView = navigationBar.superview else { return nil }
                let navigationBarFrameInWindow = navigationBarSuperView.convert(navigationBar.frame, to: nil)
                
                // crop rect top edge
                var rect = transitionMaskView.frame
                let _toViewFrameInWindow = toVC.view.superview.flatMap { $0.convert(toVC.view.frame, to: nil) }
                if let toViewFrameInWindow = _toViewFrameInWindow, toViewFrameInWindow.minY > navigationBarFrameInWindow.maxY {
                    rect.origin.y = toViewFrameInWindow.minY
                } else {
                    rect.origin.y = navigationBarFrameInWindow.maxY + UIView.separatorLineHeight(of: toVC.view)     // extra hairline
                }

                if rect.minY < snapshot.frame.minY {
                    needsMaskWithAnimation = false
                }
                
                return rect
            }()
            let maskLayerToPath = maskLayerToRect.flatMap { UIBezierPath(rect: $0) }?.cgPath

            if let maskLayer = transitionItem.interactiveTransitionMaskLayer, !needsMaskWithAnimation {
                maskLayer.path = maskLayerToPath
            }
            
            let maskLayerToFinalRect: CGRect? = {
                guard case .attachments = transitionItem.source else { return nil }
                var rect = maskLayerToRect ?? transitionMaskView.frame
                // clip rect bottom when tabBar visible
                guard let tabBarController = toVC.tabBarController,
                      !tabBarController.tabBar.isHidden,
                      let tabBarSuperView = tabBarController.tabBar.superview
                else { return rect }
                let tabBarFrameInWindow = tabBarSuperView.convert(tabBarController.tabBar.frame, to: nil)
                let offset = rect.maxY - tabBarFrameInWindow.minY
                guard offset > 0 else { return rect }
                rect.size.height -= offset
                return rect
            }()
            maskLayerToFinalPath = maskLayerToFinalRect.flatMap { UIBezierPath(rect: $0) }?.cgPath
        }

        itemAnimator.addAnimations {
            if let maskLayer = self.transitionItem.interactiveTransitionMaskLayer,
               let maskLayerToFinalPath = maskLayerToFinalPath {
                maskLayer.path = maskLayerToFinalPath
            }
            if toPosition == .end {
                switch self.transitionItem.source {
                case .profileBanner where toPosition == .end:
                    // fade transition for banner
                    self.transitionItem.containerSnapshotTransitioning?.alpha = 0
                default:
                    if let containerTargetFrame = self.transitionItem.containerTargetFrame {
                        self.transitionItem.containerSnapshotTransitioning?.frame = containerTargetFrame
                        if let targetFrame = self.transitionItem.targetFrame {
                            self.transitionItem.snapshotTransitioning?.frame = targetFrame
                        } else {
                            self.transitionItem.snapshotTransitioning?.frame.size = containerTargetFrame.size
                        }
                    } else {
                        self.transitionItem.containerSnapshotTransitioning?.alpha = 0
                    }
                }
                
            } else {
                if let initialFrame = self.transitionItem.initialFrame,
                   let initialContainerFrame = self.transitionItem.initialContainerFrame {
                    self.transitionItem.snapshotTransitioning?.frame = initialFrame
                    self.transitionItem.containerSnapshotTransitioning?.frame = initialContainerFrame
                } else {
                    self.transitionItem.containerSnapshotTransitioning?.alpha = 1
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
        let progress = abs(translation.y) / (transitionContext.containerView.bounds.height / 2)
        return progress
    }

    private func updateTransitionItemPosition(of translation: CGPoint) {
        let progress = progressStep(for: translation)

        let initialSize = transitionItem.initialFrame!.size
        guard initialSize != .zero else { return }
        // assert(initialSize != .zero)

        guard let transitionView = transitionItem.transitionView,
              let container = transitionItem.containerSnapshotTransitioning,
              let snapshot = transitionItem.snapshotTransitioning,
              let containerFinalRect = transitionItem.containerTargetFrame
        else {
            return
        }

        let snapshotFinalRect = transitionItem.targetFrame ?? containerFinalRect

        if container.frame.size == .zero && snapshot.frame.size == .zero {
            assertionFailure("divide 0 error")
            container.frame.size = initialSize
            snapshot.frame.size = initialSize
        }

        func calculateOffset(for view: UIView, finalSize: CGSize, touchOffset: inout CGVector) {
            let size = transitionView.frame.size
            if size.width == .zero || size.height == .zero {
                assertionFailure("divide 0 error")
                transitionView.frame.size = initialSize
            }

            let itemPercentComplete = clip(-0.05, 1.05, (size.width - initialSize.width) / (finalSize.width - initialSize.width) + progress)
            let itemWidth = lerp(initialSize.width, finalSize.width, itemPercentComplete)
            let itemHeight = lerp(initialSize.height, finalSize.height, itemPercentComplete)
            let scaleTransform = CGAffineTransform(scaleX: (itemWidth / size.width), y: (itemHeight / size.height))
            let scaledOffset = touchOffset.apply(transform: scaleTransform)

            let center = transitionView.convert(CGPoint(x: transitionView.bounds.midX, y: transitionView.bounds.midY), to: nil)
            view.bounds = CGRect(origin: CGPoint.zero, size: CGSize(width: itemWidth, height: itemHeight))
            view.center = (center + (translation + (touchOffset - scaledOffset))).point

            touchOffset = scaledOffset
        }

        calculateOffset(for: container, finalSize: containerFinalRect.size, touchOffset: &transitionItem.containerTouchOffset)
        calculateOffset(for: snapshot, finalSize: snapshotFinalRect.size, touchOffset: &transitionItem.touchOffset)
        snapshot.frame.origin = snapshotFinalRect == containerFinalRect ? .zero : CGPoint(
            x: progress * snapshotFinalRect.origin.x,
            y: progress * snapshotFinalRect.origin.y
        )
    }
}

