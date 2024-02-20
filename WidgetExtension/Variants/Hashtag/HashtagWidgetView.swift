// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MetaTextKit
import MastodonMeta
import MastodonLocalization

struct HashtagWidgetView: View {

    var entry: HashtagWidgetProvider.Entry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium, .systemLarge:
            viewForMediumWidget()
        case .accessoryRectangular:
            viewForRectangularAccessory()
        default:
            Text(L10n.Widget.Common.unsupportedWidgetFamily)
        }
    }

    private func viewForMediumWidget() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(entry.hashtag.accountName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(entry.hashtag.account)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.hashtag.timestamp.localizedShortTimeAgo(since: .now))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(statusWithColorHashtags: entry.hashtag.content)

            Spacer()

            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: 0) {
                    Image(systemName: "arrow.2.squarepath")
                        .foregroundColor(.secondary)
                    Text("\(entry.hashtag.reblogCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 0) {
                    Image(systemName: "star")
                        .foregroundColor(.secondary)
                    Text("\(entry.hashtag.favoriteCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(entry.hashtag.hashtag)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 29, bottom: 12, trailing: 29))
        .emptyWidgetBackground()
    }

    private func viewForRectangularAccessory() -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .center, spacing: 3) {
                Image("BrandIcon")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.secondary)
                Text("|")
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 12)))
                    .foregroundColor(.secondary)
                Text(entry.hashtag.hashtag)
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 13)))
                    .fontWeight(.heavy)
                    .foregroundColor(.secondary)
            }
            Text(statusWithColorHashtags: entry.hashtag.content, fontSize: 11, fontWeight: .medium)
                .lineLimit(3)
        }
        .emptyWidgetBackground()
    }
}

/// Inspired by: https://swiftuirecipes.com/blog/swiftui-text-with-html-via-nsattributedstring
extension Text {
    init(statusWithColorHashtags statusContent: String, fontSize: CGFloat = 16, fontWeight: UIFont.Weight = .regular) {

        let textColor = UIColor(named: "Colors/TextColor") ?? .label
        let accentColor = UIColor(named: "Colors/AccentColor") ?? .red
        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: fontSize, weight: fontWeight))

        let attributedString: AttributedString
        // 1. Render status-content as HTML ...
        if let data = statusContent.data(using: .utf8),
           let renderedString = try? NSAttributedString(data: data,
                                                        options: [
                                                            .documentType: NSAttributedString.DocumentType.html,
                                                            .characterEncoding: NSUTF8StringEncoding
                                                        ],
                                                        documentAttributes: nil) {

            // 2. let MetaTextKit do the rest
            let content = MastodonContent(content: renderedString.string, emojis: [:])
            attributedString = MastodonMetaContent.convert(text: content)
                .attributedString(textColor: textColor, accentColor: accentColor, font: font)
        } else {
            // this is a fallback
            attributedString = AttributedString(NSAttributedString(string: statusContent))
        }

        self.init(attributedString)
    }
}

#warning("Replace this once we update MetaTextKit to `4.5.2`. We should do that.")
extension MetaContent {
    public func attributedString(textColor: UIColor, accentColor: UIColor, font: UIFont) -> AttributedString {
        let attributedString = NSMutableAttributedString(string: string, attributes: [
            .foregroundColor: textColor,
            .font: font
        ])

        // meta
        let stringRange = NSRange(location: 0, length: attributedString.length)
        for entity in entities {
            let range = NSIntersectionRange(stringRange, entity.range)
            attributedString.addAttribute(.link, value: entity.encodedPrimaryText, range: range)
            attributedString.addAttribute(.foregroundColor, value: accentColor, range: range)
        }

        return AttributedString(attributedString)
    }
}

extension Meta.Entity {
    public var encodedPrimaryText: String {
        return primaryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? primaryText
    }
}
