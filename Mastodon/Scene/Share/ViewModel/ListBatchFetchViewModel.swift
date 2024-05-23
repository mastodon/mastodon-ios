//
//  ListBatchFetchViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-10.
//

import UIKit
import Combine

// ref: Texture.ASBatchFetchingDelegate
final class ListBatchFetchViewModel {
    let shouldFetch = PassthroughSubject<Void, Never>()
    
    init() {}

    static func scrollViewdidScrollToEnd(_ scrollView: UIScrollView, action: () -> Void) {
        if scrollView.isDragging || scrollView.isTracking { return }

        let frame = scrollView.frame
        let contentOffset = scrollView.contentOffset
        let contentSize = scrollView.contentSize

        let visibleBottomY = contentOffset.y + frame.height
        let offset = 2 * frame.height
        let fetchThrottleOffsetY = contentSize.height - offset

        if visibleBottomY > fetchThrottleOffsetY {
            action()
        }

    }
}

extension ListBatchFetchViewModel {
    @available(*, deprecated, message: "Implement `UIScrollViewDelegate` and invoce `scrollViewdidScrollToEnd` for now.")
    func setup(scrollView: UIScrollView) {}
}


