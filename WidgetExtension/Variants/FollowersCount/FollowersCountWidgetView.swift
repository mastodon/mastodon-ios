// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import SwiftUI
import WidgetKit
import MastodonAsset

struct FollowersCountWidgetView: View {
    private let followersHistory = FollowersCountHistory.shared

    @Environment(\.widgetFamily) var family

    var entry: FollowersCountWidgetProvider.Entry

    var body: some View {
        if let account = entry.account {
            switch family {
            case .systemSmall:
                if let showChart = entry.configuration.showChart?.boolValue, showChart {
                    viewForSmallWidgetYesChart(account)
                } else {
                    viewForSmallWidgetNoChart(account)
                }
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
    
    private func viewForSmallWidgetNoChart(_ account: FollowersEntryAccountable) -> some View {
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
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 13)))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("@\(account.acct)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.leading, 20)
            .padding(.vertical, 16)
            Spacer()
        }
    }
    
    private func viewForSmallWidgetYesChart(_ account: FollowersEntryAccountable) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let avatarImage = account.avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .frame(width: 23, height: 23)
                        .cornerRadius(5)
                }
                VStack(alignment: .leading) {
                    Text(account.displayNameWithFallback)
                        .font(.caption)
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

            ZStack {
                if let account = entry.account {
                    LightChartView(
                        data: followersHistory.chartValues(for: account),
                        type: .line,
                        visualType: .filled(color: Asset.Colors.Brand.blurple.swiftUIColor, lineWidth: 2),
                        offset: 0.8 /// this is the positive offset from the bottom edge of the graph (~80% above bottom level)
                    )
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Spacer()
                        if let increaseCount = followersHistory.increaseCountString(for: account) {
                            Text("\(increaseCount) followers today")
                                .font(.system(size: UIFontMetrics.default.scaledValue(for: 12)))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        
                        Text(account.followersCount.asAbbreviatedCountString())
                            .font(.largeTitle)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                    }
                    Spacer()
                }
                .padding(.bottom, 16)
                .padding(.leading, 20)
            }
        }
        .padding(.top, 16)
    }
    
    private func viewForAccessoryRectangular(_ account :FollowersEntryAccountable) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Image("BrandIcon")
                    Text("FOLLOWERS")
                        .font(.system(size: UIFontMetrics.default.scaledValue(for: 15), weight: .semibold))
                }
                .padding(.top, 6)

                Text(account.followersCount.asAbbreviatedCountString())
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 43)))
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
                    .font(.system(size: UIFontMetrics.default.scaledValue(for: 15)))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}
