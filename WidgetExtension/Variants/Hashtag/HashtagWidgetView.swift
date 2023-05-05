// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization

struct HashtagWidgetView: View {

    var entry: HashtagWidgetProvider.Entry

    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        switch family {
        case .systemMedium, .systemLarge:
            viewForMediumWidget(colorScheme: colorScheme)
        case .accessoryRectangular:
            viewForRectangularAccessory()
        default:
            Text(L10n.Widget.Common.unsupportedWidgetFamily)
        }
    }

    private func viewForMediumWidget(colorScheme: ColorScheme) -> some View {
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

            Text(statusHTML: entry.hashtag.content, colorScheme: colorScheme)

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
            Text(statusHTML: entry.hashtag.content, fontSize: 11, fontWeight: 510)
                .lineLimit(3)
        }
    }
}

/// Inspired by: https://swiftuirecipes.com/blog/swiftui-text-with-html-via-nsattributedstring
extension Text {
    init(statusHTML htmlString: String, fontSize: Int = 16, fontWeight: Int = 400, colorScheme: ColorScheme = .light) {

        let textColor = (UIColor(named: "Colors/TextColor") ?? UIColor.gray).hexValue
        let accentColor = (UIColor(named: "Colors/Blurple") ?? UIColor.purple).hexValue

        let fullHTML = """
<!doctype html>
<html>
    <head>
        <style>
                body {
                    font-family: -apple-system;
                    font-size: \(fontSize)px;
                    font-weight: \(fontWeight);
                    line-height: 133%;
                    color: \(textColor);
                }

                a {
                    color: \(accentColor);
                }
            }
        </style>
    </head>
    <body>
        \(htmlString)
    </body>
  </html>
"""

        let attributedString: NSAttributedString
        if let data = fullHTML.data(using: .unicode),
           let attrString = try? NSAttributedString(data: data,
                                                    options: [.documentType: NSAttributedString.DocumentType.html],
                                                    documentAttributes: nil) {
            attributedString = attrString
        } else {
            attributedString = NSAttributedString()
        }

        self.init(AttributedString(attributedString)) // uses the NSAttributedString initializer
    }
}
