//
//  MetaText.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-22.
//

import UIKit
import Meta
import MetaTextKit
import MastodonAsset

extension MetaLabel {
    public enum Style {
        case statusHeader
        case statusName
        case statusUsername
        case statusSpoilerOverlay
        case statusSpoilerBanner
        case notificationTitle
        case profileFieldName
        case profileFieldValue
        case profileCardName
        case profileCardUsername
        case profileCardFamiliarFollowerFooter
        case recommendAccountName
        case titleView
        case autoCompletion
        case accountListName
        case accountListUsername
        case sidebarHeadline(isSelected: Bool)
        case sidebarSubheadline(isSelected: Bool)
    }

    public convenience init(style: Style) {
        self.init()

        layer.masksToBounds = true
        lineBreakMode = .byTruncatingTail
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0
        
        setup(style: style)
    }
    
    public func setup(style: Style) {
        let font: UIFont
        let textColor: UIColor
        
        switch style {
        case .statusHeader:
            font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .bold))
            textColor = Asset.Colors.Label.secondary.color
            
        case .statusName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
            textColor = Asset.Colors.Label.primary.color
            
        case .statusUsername:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular))
            textColor = Asset.Colors.Label.secondary.color
            
        case .statusSpoilerOverlay:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 20, weight: .semibold))
            textColor = Asset.Colors.Label.primary.color
            textAlignment = .center
            paragraphStyle.alignment = .center
            numberOfLines = 0
            textContainer.maximumNumberOfLines = 0

        case .statusSpoilerBanner:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
            textColor = Asset.Colors.Label.primary.color
            
        case .notificationTitle:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 14, weight: .regular))
            textColor = Asset.Colors.Label.secondary.color
            
        case .profileFieldName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 13, weight: .semibold))
            textColor = Asset.Colors.Label.secondary.color
            
        case .profileFieldValue:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular))
            textColor = Asset.Colors.Label.primary.color
            
        case .profileCardName:
            font = .systemFont(ofSize: 17, weight: .semibold)
            textColor = Asset.Colors.Label.primary.color
            
        case .profileCardUsername:
            font = .systemFont(ofSize: 15, weight: .regular)
            textColor = Asset.Colors.Label.secondary.color
            
        case .profileCardFamiliarFollowerFooter:
            font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .regular), maximumPointSize: 26)
            textColor = Asset.Colors.Label.secondary.color
            numberOfLines = 2
            textContainer.maximumNumberOfLines = 2
            paragraphStyle.lineSpacing = 0
            paragraphStyle.paragraphSpacing = 0
            
        case .titleView:
            font = .systemFont(ofSize: 17, weight: .semibold)
            textColor = Asset.Colors.Label.primary.color
            textAlignment = .center
            paragraphStyle.alignment = .center
            
        case .recommendAccountName:
            font = .systemFont(ofSize: 18, weight: .semibold)
            textColor = .white
            
        case .autoCompletion:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: 22)
            textColor = Asset.Colors.Brand.blurple.color
            
        case .accountListName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 22)
            textColor = Asset.Colors.Label.primary.color
            
        case .accountListUsername:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .regular), maximumPointSize: 20)
            textColor = Asset.Colors.Label.secondary.color
            
        case .sidebarHeadline(let isSelected):
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 22, weight: .regular), maximumPointSize: 20)
            textColor = isSelected ? .white : Asset.Colors.Label.primary.color
            
        case .sidebarSubheadline(let isSelected):
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 13, weight: .regular), maximumPointSize: 18)
            textColor = isSelected ? .white : Asset.Colors.Label.secondary.color
        }
        
        self.font = font
        self.textColor = textColor
        
        textAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]
        linkAttributes = [
            .font: font,
            .foregroundColor: Asset.Colors.Brand.blurple.color
        ]
    }

    public var backedString: String {
        let string = textStorage.string
        let nsString = NSMutableString(string: string)
        textStorage.enumerateAttribute(
            .attachment,
            in: NSRange(location: 0, length: textStorage.length),
            options: [.reverse])
        { value, range, _ in
            guard let attachment = value as? MetaAttachment else { return }
            nsString.replaceCharacters(in: range, with: attachment.string)
        }
        return nsString as String
    }

}
