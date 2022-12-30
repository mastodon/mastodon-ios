//
//  HashtagTimelineHeaderViewActionButton.swift
//  Mastodon
//
//  Created by Marcus Kida on 25.11.22.
//

import UIKit
import MastodonUI
import MastodonAsset

class HashtagTimelineHeaderViewActionButton: RoundedEdgesButton {

    init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        let shadowColor: UIColor = {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return .darkGray
            default:
                return .lightGray
            }
        }()
        
        layer.setupShadow(
            color: shadowColor,
            alpha: 1,
            x: 0,
            y: 1,
            blur: 2,
            spread: 0,
            roundedRect: bounds,
            byRoundingCorners: .allCorners,
            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
        )
    }
}

