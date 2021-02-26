//
//  TimelineBottomLoaderTableViewCell.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/3.
//

import UIKit
import Combine

final class TimelineBottomLoaderTableViewCell: TimelineLoaderTableViewCell {
    override func _init() {
        super._init()
        backgroundColor = .clear

        activityIndicatorView.isHidden = false
        activityIndicatorView.startAnimating()
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

