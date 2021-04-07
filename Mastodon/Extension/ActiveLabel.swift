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
        case profileField
    }
    
    convenience init(style: Style) {
        self.init()
    
        numberOfLines = 0
        lineSpacing = 5
        mentionColor = Asset.Colors.Label.highlight.color
        hashtagColor = Asset.Colors.Label.highlight.color
        URLColor = Asset.Colors.Label.highlight.color
        #if DEBUG
        text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        #endif
        
        switch style {
        case .default:
            font = .preferredFont(forTextStyle: .body)
            textColor = Asset.Colors.Label.primary.color
        case .profileField:
            font = .preferredFont(forTextStyle: .body)
            textColor = Asset.Colors.Label.primary.color
            numberOfLines = 1
        }
    }
    
}

extension ActiveLabel {
    /// status content
    func configure(content: String) {
        activeEntities.removeAll()
        if let parseResult = try? MastodonStatusContent.parse(status: content) {
            text = parseResult.trimmed
            activeEntities = parseResult.activeEntities
        } else {
            text = ""
        }
    }
    
    /// account note
    func configure(note: String) {
        configure(content: note)
    }
}

extension ActiveLabel {
    /// account field
    func configure(field: String) {
        activeEntities.removeAll()
        let parseResult = MastodonField.parse(field: field)
        text = parseResult.value
        activeEntities = parseResult.activeEntities
    }
}
