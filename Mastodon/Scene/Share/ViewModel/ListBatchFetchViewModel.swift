//
//  ListBatchFetchViewModel.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-10.
//

import UIKit

final class ListBatchFetchViewModel {
    static func scrollViewDidScrollToEnd(_ scrollView: UIScrollView, action: () -> Void) {
        if scrollView.isDragging || scrollView.isTracking { return }

        let frame = scrollView.frame
        let contentOffset = scrollView.contentOffset
        let contentSize = scrollView.contentSize

        // if not enough content to fill the screen: don't do anything
        if contentSize.height < frame.height { return }

        if contentOffset.y > (contentSize.height - frame.height) {
            action()
        }
    }
}
