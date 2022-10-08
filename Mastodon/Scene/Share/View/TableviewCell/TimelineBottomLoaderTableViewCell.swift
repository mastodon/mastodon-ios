//
//  TimelineBottomLoaderTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/3.
//

import UIKit
import Combine
import MastodonCore
import MastodonUI

final class TimelineBottomLoaderTableViewCell: TimelineLoaderTableViewCell {

    override func prepareForReuse() {
        super.prepareForReuse()

        loadMoreLabel.isHidden = true
        loadMoreButton.isHidden = true
    }

    override func _init() {
        super._init()
        
        activityIndicatorView.isHidden = false
        startAnimating()
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TimelineBottomLoaderTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            TimelineBottomLoaderTableViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

