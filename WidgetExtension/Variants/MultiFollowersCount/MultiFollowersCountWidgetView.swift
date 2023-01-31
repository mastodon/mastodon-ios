// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import WidgetKit
import MastodonAsset

struct MultiFollowersCountWidgetView: View {
    @Environment(\.widgetFamily) var family

    var entry: MultiFollowersCountWidgetProvider.Entry

    var body: some View {
        if let accounts = entry.accounts {
            switch family {
            case .systemSmall:
                viewForSmallWidgetNoChart(accounts)
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
    
    private func viewForSmallWidgetNoChart(_ accounts: [FollowersEntryAccountable]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(accounts, id: \.acct) { account in
                HStack {
                    if let avatarImage = account.avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .cornerRadius(5)
                    }
                    VStack(alignment: .leading) {
                        Text(account.followersCount.asAbbreviatedCountString())
                            .font(.title2)
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
                .padding(.leading, 20)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }
}
