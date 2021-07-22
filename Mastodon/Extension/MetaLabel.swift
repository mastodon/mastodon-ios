//
//  MetaText.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-22.
//

import UIKit
import MetaTextKit

extension MetaLabel {
    enum Style {
        case statusHeader
        case statusName
//        case profileFieldName
//        case profileFieldValue
    }

    convenience init(style: Style) {
        self.init()

        layer.masksToBounds = true
        textContainer.lineBreakMode = .byTruncatingTail

        let font: UIFont
        let textColor: UIColor

        switch style {
        case .statusHeader:
            font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 13, weight: .medium), maximumPointSize: 17)
            textColor = Asset.Colors.Label.secondary.color

        case .statusName:
            font = .systemFont(ofSize: 17, weight: .semibold)
            textColor = Asset.Colors.Label.primary.color
//        case .profileFieldName:
//            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: 20)
//            textColor = Asset.Colors.Label.primary.color
//            numberOfLines = 1
//        case .profileFieldValue:
//            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .regular), maximumPointSize: 20)
//            textColor = Asset.Colors.Label.primary.color
//            numberOfLines = 1
        }

        self.font = font
        self.textColor = textColor
        
        textAttributes = [
            .font: font,
            .foregroundColor: textColor
        ]
    }}
