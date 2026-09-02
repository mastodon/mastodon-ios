//
//  MetaLabel.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-22.
//

import UIKit
import MetaTextKit
import MastodonAsset

extension MetaLabel {
    public enum Style {
        case statusName
        case autoCompletion
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
        case .statusName:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 15, weight: .semibold))
            textColor = Asset.Colors.Label.primary.color
            
        case .autoCompletion:
            font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 17, weight: .semibold), maximumPointSize: 22)
            textColor = Asset.Colors.Brand.blurple.color
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

}
