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
        case statusHeader
        case statusName
        case profileField
    }
    
    convenience init(style: Style) {
        self.init()
    
        numberOfLines = 0
        lineSpacing = 5
        mentionColor = Asset.Colors.Label.highlight.color
        hashtagColor = Asset.Colors.Label.highlight.color
        URLColor = Asset.Colors.Label.highlight.color
        emojiPlaceholderColor = .systemFill
        #if DEBUG
        text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
        #endif
        
        switch style {
        case .default:
            font = .preferredFont(forTextStyle: .body)
            textColor = Asset.Colors.Label.primary.color
        case .statusHeader:
            font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .medium), maximumPointSize: 17)
            textColor = Asset.Colors.Label.secondary.color
            numberOfLines = 1
        case .statusName:
            font = .systemFont(ofSize: 17, weight: .semibold)
            textColor = Asset.Colors.Label.primary.color
            numberOfLines = 1
        case .profileField:
            font = .preferredFont(forTextStyle: .body)
            textColor = Asset.Colors.Label.primary.color
            numberOfLines = 1
        }
    }
    
}

extension ActiveLabel {
    /// status content
    func configure(content: String, emojiDict: MastodonStatusContent.EmojiDict) {
        activeEntities.removeAll()
        
        if let parseResult = try? MastodonStatusContent.parse(content: content, emojiDict: emojiDict) {
            text = parseResult.trimmed
            activeEntities = parseResult.activeEntities
        } else {
            text = ""
        }
    }
    
    /// account note
    func configure(note: String, emojiDict: MastodonStatusContent.EmojiDict) {
        configure(content: note, emojiDict: emojiDict)
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
