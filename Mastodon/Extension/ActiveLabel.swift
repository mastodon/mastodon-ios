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
        case profileFieldName
        case profileFieldValue
    }
    
    convenience init(style: Style) {
        self.init()
    
        numberOfLines = 0
        lineSpacing = 5
        mentionColor = Asset.Colors.brandBlue.color
        hashtagColor = Asset.Colors.brandBlue.color
        URLColor = Asset.Colors.brandBlue.color
        emojiPlaceholderColor = .systemFill
        
        accessibilityContainerType = .semanticGroup
        
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
        case .profileFieldName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: 20)
            textColor = Asset.Colors.Label.primary.color
            numberOfLines = 1
        case .profileFieldValue:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 20)
            textColor = Asset.Colors.Label.primary.color
            numberOfLines = 1
        }
    }
    
}

extension ActiveLabel {
    func configure(text: String) {
        attributedText = nil
        activeEntities.removeAll()
        self.text = text
        accessibilityLabel = text
    }
}

extension ActiveLabel {
    
    /// status content
    func configure(content: String, emojiDict: MastodonStatusContent.EmojiDict) {
        attributedText = nil
        activeEntities.removeAll()
        
        if let parseResult = try? MastodonStatusContent.parse(content: content, emojiDict: emojiDict) {
            text = parseResult.trimmed
            activeEntities = parseResult.activeEntities
            accessibilityLabel = parseResult.original
        } else {
            text = ""
            accessibilityLabel = nil
        }
    }
    
    func configure(contentParseResult parseResult: MastodonStatusContent.ParseResult?) {
        attributedText = nil
        activeEntities.removeAll()
        text = parseResult?.trimmed ?? ""
        activeEntities = parseResult?.activeEntities ?? []
        accessibilityLabel = parseResult?.original ?? nil
    }
    
    /// account note
    func configure(note: String, emojiDict: MastodonStatusContent.EmojiDict) {
        configure(content: note, emojiDict: emojiDict)
    }
}

extension ActiveLabel {
    /// account field
    func configure(field: String, emojiDict: MastodonStatusContent.EmojiDict) {
        configure(content: field, emojiDict: emojiDict)
    }
}

extension ActiveEntity {
    
    var accessibilityLabelDescription: String {
        switch self.type {
        case .email:    return L10n.Common.Controls.Status.Tag.email
        case .hashtag:  return L10n.Common.Controls.Status.Tag.hashtag
        case .mention:  return L10n.Common.Controls.Status.Tag.mention
        case .url:      return L10n.Common.Controls.Status.Tag.url
        case .emoji:    return L10n.Common.Controls.Status.Tag.emoji
        }
    }
    
    var accessibilityValueDescription: String {
        switch self.type {
        case .email(let text, _):           return text
        case .hashtag(let text, _):         return text
        case .mention(let text, _):         return text
        case .url(_, let trimmed, _, _):    return trimmed
        case .emoji(let text, _, _):        return text
        }
    }
    
    func accessibilityElement(in accessibilityContainer: Any) -> ActiveLabelAccessibilityElement? {
        if case .emoji = self.type {
            return nil
        }
        
        let element = ActiveLabelAccessibilityElement(accessibilityContainer: accessibilityContainer)
        element.accessibilityTraits = .button
        element.accessibilityLabel = accessibilityLabelDescription
        element.accessibilityValue = accessibilityValueDescription
        return element
    }
}

final class ActiveLabelAccessibilityElement: UIAccessibilityElement {
    var index: Int!
}

// MARK: - UIAccessibilityContainer
extension ActiveLabel {
    
    func createAccessibilityElements() -> [UIAccessibilityElement] {
        var elements: [UIAccessibilityElement] = []
        
        let element = ActiveLabelAccessibilityElement(accessibilityContainer: self)
        element.accessibilityTraits = .staticText
        element.accessibilityLabel = accessibilityLabel
        element.accessibilityFrame = superview!.convert(frame, to: nil)
        element.accessibilityLanguage = accessibilityLanguage
        elements.append(element)
        
        for entity in activeEntities {
            guard let element = entity.accessibilityElement(in: self) else { continue }
            var glyphRange = NSRange()
            layoutManager.characterRange(forGlyphRange: entity.range, actualGlyphRange: &glyphRange)
            let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
            element.accessibilityFrame = self.convert(rect, to: nil)
            element.accessibilityContainer = self
            elements.append(element)
        }
        
        return elements
    }
    
}
