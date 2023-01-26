// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import WidgetKit

struct FollowCountWidgetView: View {
    @Environment(\.widgetFamily) var family

    var entry: FollowersProvider.Entry

    var body: some View {
        if let account = entry.account {
            switch family {
            case .systemSmall:
                viewForSmallWidget(account)
            case .accessoryRectangular:
                viewForAccessoryRectangular(account)
            case .accessoryCircular:
                viewForAccessoryCircular(account)
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
    
    private func viewForSmallWidget(_ account: FollowersEntryAccountable) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                if let avatarImage = account.avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .cornerRadius(12)
                        .padding(.bottom, 8)
                }
                
                Text(account.followersCount.asAbbreviatedCountString())
                    .font(.largeTitle)
                    .lineLimit(1)
                    .truncationMode(.tail)
            
                Text(account.displayNameWithFallback)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("@\(account.acct)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.leading, 20)
            .padding([.top, .bottom], 16)
            Spacer()
        }
    }
    
    private func viewForAccessoryRectangular(_ account :FollowersEntryAccountable) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Image("BrandIcon")
                    Text("FOLLOWERS")
                        .font(.system(size: 15, weight: .semibold))
                }
                .padding(.top, 6)

                Text(account.followersCount.asAbbreviatedCountString())
                    .font(.system(size: 43))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer()
        }
    }
    
    private func viewForAccessoryCircular(_ account :FollowersEntryAccountable) -> some View {
        ZStack {
            if #available(iOS 16, *) {
                AccessoryWidgetBackground()
            }
            VStack {
                Image("BrandIcon")

                Text(account.followersCount.asAbbreviatedCountString())
                    .font(.system(size: 15))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}
