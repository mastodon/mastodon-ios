//
//  MetaText.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-22.
//

import UIKit
import Meta
import MetaTextKit

extension MetaLabel {
    enum Style {
        case statusHeader
        case statusName
        case notificationName
        case profileFieldName
        case profileFieldValue
        case recommendAccountName
        case titleView
        case settingTableFooter
    }

    convenience init(style: Style) {
        self.init()

        layer.masksToBounds = true
        textContainer.lineBreakMode = .byTruncatingTail
        textContainer.lineFragmentPadding = 0
        
        let font: UIFont
        let textColor: UIColor

        switch style {
        case .statusHeader:
            font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .medium), maximumPointSize: 17)
            textColor = Asset.Colors.Label.secondary.color

        case .statusName:
            font = .systemFont(ofSize: 17, weight: .semibold)
            textColor = Asset.Colors.Label.primary.color

        case .notificationName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold), maximumPointSize: 20)
            textColor = Asset.Colors.brandBlue.color

        case .profileFieldName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: 20)
            textColor = Asset.Colors.Label.primary.color

        case .profileFieldValue:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 20)
            textColor = Asset.Colors.Label.primary.color
            textAlignment = .right


        case .titleView:
            font = .systemFont(ofSize: 17, weight: .semibold)
            textColor = Asset.Colors.Label.primary.color
            textAlignment = .center
            paragraphStyle.alignment = .center

        case .recommendAccountName:
            font = .systemFont(ofSize: 18, weight: .semibold)
            textColor = .white

        case .settingTableFooter:
            font = .preferredFont(forTextStyle: .body)
            textColor = Asset.Colors.Label.secondary.color
            numberOfLines = 0
            textContainer.maximumNumberOfLines = 0
            paragraphStyle.alignment = .center
        }

        self.font = font
        self.textColor = textColor
        
        textAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]
        linkAttributes = [
            .font: font,
            .foregroundColor: Asset.Colors.brandBlue.color
        ]
    }

}

struct PlaintextMetaContent: MetaContent {
    let string: String
    let entities: [Meta.Entity] = []

    init(string: String) {
        self.string = string
    }

    func metaAttachment(for entity: Meta.Entity) -> MetaAttachment? {
        return nil
    }
}
