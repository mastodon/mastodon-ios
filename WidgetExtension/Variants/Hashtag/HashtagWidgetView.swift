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
                Text(entry.hashtag.account)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(entry.hashtag.timestamp.localizedShortTimeAgo(since: .now))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            //TODO: Check MetaLabelRepresentable, maybe it's a way to color Hashtags?
            Text(entry.hashtag.content)

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
            HStack(spacing: 3) {
                Image("BrandIcon")
                    .foregroundColor(.secondary)
                Text("|")
                    .foregroundColor(.secondary)
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 9)))
                Text(entry.hashtag.hashtag)
                    .foregroundColor(.secondary)
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 13)))
                    .fontWeight(.heavy)

            }
            Text(entry.hashtag.content)
                .foregroundColor(.primary)
                .font(.system(size: UIFontMetrics.default.scaledValue(for: 16)))
                .fontWeight(.medium)
                .lineLimit(3)
            Spacer()
        }
    }
}
