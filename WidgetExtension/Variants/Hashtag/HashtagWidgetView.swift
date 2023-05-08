// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
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
    }
}

/// Inspired by: https://swiftuirecipes.com/blog/swiftui-text-with-html-via-nsattributedstring
extension Text {
    init(statusWithColorHashtags htmlString: String, fontSize: CGFloat = 16, fontWeight: UIFont.Weight = .regular) {

        let textColor = UIColor(named: "Colors/TextColor")
        let accentColor = UIColor(named: "Colors/AccentColor")
        let font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: fontSize, weight: fontWeight))

        let attributedString: AttributedString

        // 1. Render status-content as HTML ...
        if let data = htmlString.data(using: .utf8),
           let renderedString = try? NSAttributedString(data: data,
                                                        options: [
                                                            .documentType: NSAttributedString.DocumentType.html,
                                                            .characterEncoding: NSUTF8StringEncoding
                                                        ],
                                                        documentAttributes: nil) {


            // 2. get the raw string ...
            let rawString = renderedString.string

            // 3. ... and use regex to get the hashtags
            let hashtagRegex = try? NSRegularExpression(pattern: "(#\\w*)")
            let hashtagRanges = hashtagRegex?.matches(
                in: rawString,
                range: NSMakeRange(0, rawString.count)
            ).compactMap { NSMakeRange($0.range.location, $0.range.length) } ?? []

            let mutableAttributedString = NSMutableAttributedString(
                string: rawString,
                attributes: [
                    .foregroundColor: textColor ?? UIColor.label,
                    .font: font
                ]
            )

            // 4. color the hashtags
            hashtagRanges.forEach {
                mutableAttributedString.setAttributes([
                    .foregroundColor: accentColor ?? UIColor.red
                ], range: $0)
            }

            attributedString = AttributedString(mutableAttributedString)
        } else {
            // this is a fallback
            attributedString = AttributedString(NSAttributedString(string: htmlString))
        }

        self.init(attributedString)
    }
}
