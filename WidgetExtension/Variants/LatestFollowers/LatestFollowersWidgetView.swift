// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import WidgetKit
import MastodonSDK
import MastodonAsset
import MastodonUI

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
                Text("Sorry but this Widget family is unsupported.")
            }
        } else {
            Text("Please open Mastodon to log in to an Account.")
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(.all, 20)
        }
    }
    
    private func viewForSmallWidget(_ accounts: [LatestFollowersEntryAccountable], lastUpdate: Date) -> some View {
        VStack(alignment: .leading) {
            Text("Latest followers")
                .font(.system(size: UIFontMetrics.default.scaledValue(for: 16)))
            
            ForEach(accounts, id: \.acct) { account in
                HStack {
                    if let avatarImage = account.avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .cornerRadius(5)
                    }
                    VStack(alignment: .leading) {
                        
                    Text(account.displayNameWithFallback)
                        .font(.footnote.bold())
                        .foregroundColor(.secondary)
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
            Text("Last update: \(dateFormatter.string(from: lastUpdate))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private func viewForMediumWidget(_ accounts: [LatestFollowersEntryAccountable], lastUpdate: Date) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Latest followers")
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 16)))
                Spacer()
                Image("BrandIconColored")
            }
            
            ForEach(accounts, id: \.acct) { account in
                HStack {
                    if let avatarImage = account.avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .cornerRadius(5)
                    }
                    VStack(alignment: .leading) {
                        
                        HStack {
                            Text(account.displayNameWithFallback)
                                .font(.footnote.bold())
                                .foregroundColor(.secondary)
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
            Text("Last update: \(dateFormatter.string(from: lastUpdate))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

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
