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

    static func scrollViewDidScrollToEnd(_ scrollView: UIScrollView, action: () -> Void) {
        if scrollView.isDragging || scrollView.isTracking { return }

        let frame = scrollView.frame
        let contentOffset = scrollView.contentOffset
        let contentSize = scrollView.contentSize

        // if not enough content to fill the screen: don't do anything
        if contentSize.height < frame.height { return }

        if contentOffset.y > (contentSize.height - frame.height) {
            print("ACTION!")
            action()
        }
    }
}

extension ListBatchFetchViewModel {
    @available(*, deprecated, message: "Implement `UIScrollViewDelegate` and invoce `scrollViewdidScrollToEnd` for now.")
    func setup(scrollView: UIScrollView) {}
}
