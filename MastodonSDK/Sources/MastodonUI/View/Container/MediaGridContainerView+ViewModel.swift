//
//  MediaGridContainerView+ViewModel.swift
//
//
//  Created by MainasuK on 2021-12-14.
//

import UIKit
import Combine

extension MediaGridContainerView {
    public class ViewModel {
        var disposeBag = Set<AnyCancellable>()
        
        
        @Published public var isSensitiveToggleButtonDisplay: Bool = false
        @Published public var isContentWarningOverlayDisplay: Bool? = nil
    }
}

extension MediaGridContainerView.ViewModel {
    
    func resetContentWarningOverlay() {
        isContentWarningOverlayDisplay = nil
    }
    
    func bind(view: MediaGridContainerView) {
        $isSensitiveToggleButtonDisplay
            .sink { isDisplay in
                view.sensitiveToggleButtonBlurVisualEffectView.isHidden = !isDisplay
            }
            .store(in: &disposeBag)
        $isContentWarningOverlayDisplay
            .sink { isDisplay in
                assert(Thread.isMainThread)
                guard let isDisplay = isDisplay else { return }
                let withAnimation = self.isContentWarningOverlayDisplay != nil
                view.configureOverlayDisplay(isDisplay: isDisplay, animated: withAnimation)
            }
            .store(in: &disposeBag)
    }
    
}

extension MediaGridContainerView {
    func configureOverlayDisplay(isDisplay: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.33, delay: 0, options: .curveEaseInOut) {
                self.contentWarningOverlayView.blurVisualEffectView.alpha = isDisplay ? 1 : 0
            }
        } else {
            contentWarningOverlayView.blurVisualEffectView.alpha = isDisplay ? 1 : 0
        }
        
        contentWarningOverlayView.isUserInteractionEnabled = isDisplay
        contentWarningOverlayView.tapGestureRecognizer.isEnabled = isDisplay
    }
}
