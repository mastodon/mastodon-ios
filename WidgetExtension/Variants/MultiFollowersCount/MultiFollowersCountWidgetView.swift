// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import WidgetKit
import MastodonAsset
import MastodonLocalization

struct MultiFollowersCountWidgetView: View {
    @Environment(\.widgetFamily) var family

    var entry: MultiFollowersCountWidgetProvider.Entry

    var body: some View {
        if let accounts = entry.accounts {
            switch family {
            case .systemSmall:
                viewForSmallWidget(accounts)
            case .systemMedium:
                viewForMediumWidget(accounts)
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
    
    private func viewForSmallWidget(_ accounts: [MultiFollowersEntryAccountable]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(accounts, id: \.acct) { account in
                HStack {
                    Image(uiImage: account.avatarImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .cornerRadius(5)
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
        .emptyWidgetBackground()
    }
    
    private func viewForMediumWidget(_ accounts: [MultiFollowersEntryAccountable]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]) {
                ForEach(accounts, id: \.acct) { account in
                    HStack {
                        Image(uiImage: account.avatarImage)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .cornerRadius(5)
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
            }
            Spacer()
        }
        .padding(.vertical, 16)
        .emptyWidgetBackground()
    }
}
