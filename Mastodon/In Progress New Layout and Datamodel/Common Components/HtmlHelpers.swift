// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonAsset
import MastodonMeta
import MetaTextKit
import MastodonCore
import UIKit
import SwiftUI
import MastodonSDK

typealias AttributeDictionary = [NSAttributedString.Key: Any]

enum MastodonHtmlFormat {
    case inlinePostPreview
    case fullPost
    case authorHeader
    case socialContextHeader
    case socialContextHeaderPrivate
    case linkPreviewCardAuthor
    case pollOption
}
    
extension MastodonHtmlFormat {
    
    public var metaText: MetaText {
        let meta = MetaText()
        meta.textAttributes = self.textAttributes
        meta.linkAttributes = self.linkAttributes
        return meta
    }
    
    private var baseFontSize: CGFloat {
        switch self {
        case .inlinePostPreview:
            10
        case .fullPost, .authorHeader, .pollOption:
            17
        case .socialContextHeader, .socialContextHeaderPrivate:
            13
        case .linkPreviewCardAuthor:
            14
        }
    }
    
    private var textAttributes: AttributeDictionary {
        switch self {
        case .inlinePostPreview:
            [:]
        case .fullPost:
            [
                .font : UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: baseFontSize, weight: .regular)),
                .foregroundColor : UIColor.label,
            ]
        case .pollOption:
            [
                .font : UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: baseFontSize, weight: .semibold)),
                .foregroundColor : UIColor.label,
            ]
        case .authorHeader:
            [
                .font : UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: baseFontSize, weight: .semibold)),
                .foregroundColor : UIColor.label,
            ]
        case .socialContextHeader:
            [
                .font : UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: baseFontSize, weight: .bold)),
                .foregroundColor : UIColor.secondaryLabel,
            ]
        case .socialContextHeaderPrivate:
            [
                .font : UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: baseFontSize, weight: .bold)),
                .foregroundColor : Asset.Colors.accent.color,
            ]
        case .linkPreviewCardAuthor:
            [
                .font : UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: baseFontSize, weight: .semibold)),
                .foregroundColor : UIColor.label
            ]
        }
    }
    
    private var linkAttributes: AttributeDictionary {
        switch self {
        case .inlinePostPreview:
            [:]
        case .fullPost, .pollOption:
            [
                .font: UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: baseFontSize, weight: .semibold)),
                .foregroundColor: UIColor.link,
            ]
        case .socialContextHeader, .socialContextHeaderPrivate:
            [:]
        case .linkPreviewCardAuthor, .authorHeader:
            [:]
        }
    }
    
    
    private var nilOptions: AttributeDictionary {
        return [:]
    }
}


@available(*, deprecated, message: "SwiftUI cannot display custom emojis. Prefer the MetaText wrapper MetaTextViewSwiftUI.") // TODO: implement option on TextViewWithCustomEmoji to bold a substring
func attributedString(
    fromHtml html: String, emojis: [MastodonContent.Shortcode: String], withFormat format: MastodonHtmlFormat? = .inlinePostPreview
) -> AttributedString {
    let content = MastodonContent(content: html, emojis: emojis)
    let metaText = format!.metaText
    metaText.reset()
    do {
        let metaContent = try MastodonMetaContent.convert(document: content)
        metaText.configure(
            content: metaContent)
        guard
            let nsAttributedString = metaText
                .textView.attributedText
        else {
            throw AppError.unexpected(
                "could not get attributed string from html")
        }
        return AttributedString(nsAttributedString)
    } catch {
        return AttributedString(html)
    }
}
