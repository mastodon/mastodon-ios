//
//  ActiveLabel.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/29.
//

import UIKit
import Foundation
import ActiveLabel
import os.log

extension ActiveLabel {
    
    enum Style {
        case `default`
        case timelineHeaderView
    }
    
    convenience init(style: Style) {
        self.init()
    
        switch style {
        case .default:
            font = .preferredFont(forTextStyle: .body)
            textColor = Asset.Colors.Label.primary.color
        case .timelineHeaderView:
            font = .preferredFont(forTextStyle: .footnote)
            textColor = .secondaryLabel
        }
        
        numberOfLines = 0
        lineSpacing = 5
        mentionColor = Asset.Colors.Label.highlight.color
        hashtagColor = Asset.Colors.Label.highlight.color
        URLColor = Asset.Colors.Label.highlight.color
        text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
    }
    
}

extension ActiveLabel {
    func config(content: String) {
        if let parseResult = try? TootContent.parse(toot: content) {
            activeEntities.removeAll()
            text = parseResult.trimmed
            activeEntities = parseResult.activeEntities
        }
    }
}

