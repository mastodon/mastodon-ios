//
//  TimelineTopLoaderTableViewCell.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import UIKit
import Combine
import MastodonCore

public final class TimelineTopLoaderTableViewCell: TimelineLoaderTableViewCell {
    public override func _init() {
        super._init()
        
        activityIndicatorView.isHidden = false
        
        startAnimating()
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct TimelineTopLoaderTableViewCell_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview(width: 375) {
            TimelineTopLoaderTableViewCell()
        }
        .previewLayout(.fixed(width: 375, height: 100))
    }
    
}

#endif

