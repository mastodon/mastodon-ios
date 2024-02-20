// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import WidgetKit
import MastodonSDK
import MastodonAsset
import MastodonUI
import MastodonLocalization

struct LatestFollowersWidgetView: View {
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    @Environment(\.widgetFamily) var family

    var entry: LatestFollowersWidgetProvider.Entry
    
    var body: some View {
        if let accounts = entry.accounts {
            switch family {
            case .systemSmall:
                viewForSmallWidget(accounts, lastUpdate: entry.date)
            case .systemMedium:
                viewForMediumWidget(accounts, lastUpdate: entry.date)
            default:
                Text(L10n.Widget.Common.unsupportedWidgetFamily)
            }
        } else {
            Text(L10n.Widget.Common.userNotLoggedIn)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.all, 20)
                .emptyWidgetBackground()
        }
    }
    
    private func viewForSmallWidget(_ accounts: [LatestFollowersEntryAccountable], lastUpdate: Date) -> some View {
        VStack(alignment: .leading) {
            Text(L10n.Widget.LatestFollowers.title)
                .font(.system(size: UIFontMetrics.default.scaledValue(for: 16)))
            
            ForEach(accounts, id: \.acct) { account in
                HStack {
                    Image(uiImage: account.avatarImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .cornerRadius(5)
                    VStack(alignment: .leading) {
                        
                    Text(account.displayNameWithFallback)
                        .font(.footnote.bold())
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text("@\(account.acct)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
     
                    }
                    Spacer()
                }
            }
            Spacer()
            Text(L10n.Widget.LatestFollowers.lastUpdate(dateFormatter.string(from: lastUpdate)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .emptyWidgetBackground()
    }
    
    private func viewForMediumWidget(_ accounts: [LatestFollowersEntryAccountable], lastUpdate: Date) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(L10n.Widget.LatestFollowers.title)
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 16)))
                Spacer()
                Image("BrandIconColored")
            }
            
            ForEach(accounts, id: \.acct) { account in
                HStack {
                    Image(uiImage: account.avatarImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .cornerRadius(5)
                    VStack(alignment: .leading) {
                        
                        HStack {
                            Text(account.displayNameWithFallback)
                                .font(.footnote.bold())
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text("@\(account.acct)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        Text(account.noteWithoutHtmlTags ?? "")
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    Spacer()
                }
            }
            Spacer()
            Text(L10n.Widget.LatestFollowers.lastUpdate(dateFormatter.string(from: lastUpdate)))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .emptyWidgetBackground()
    }
}

/// This code is used to strip HTML tags from the bio description as the widgets currently dont support
/// rich text rendering due to the lack of SwiftUI-only components for this purpose.
/// todo: Implement rich text rendering for bio description and remove this code
/// https://github.com/mastodon/mastodon-ios/issues/921
private extension LatestFollowersEntryAccountable {
    var noteWithoutHtmlTags: String? {
        do {
            let regex =  "<[^>]+>"
            let expr = try NSRegularExpression(pattern: regex, options: NSRegularExpression.Options.caseInsensitive)
            let result = expr.stringByReplacingMatches(in: note, options: [], range: NSMakeRange(0, note.count), withTemplate: "")
            return result
        } catch {
            return nil
        }
    }
}
