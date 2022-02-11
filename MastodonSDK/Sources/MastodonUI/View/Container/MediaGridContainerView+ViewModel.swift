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
    }
}

extension MediaGridContainerView.ViewModel {
    
    func bind(view: MediaGridContainerView) {
        $isSensitiveToggleButtonDisplay
            .sink { isDisplay in
                // view.sensitiveToggleButtonBlurVisualEffectView.isHidden = !isDisplay
            }
            .store(in: &disposeBag)
    }
    
}
