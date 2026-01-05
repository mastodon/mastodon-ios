// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import MastodonUI
import SwiftUI

struct AccountStatsView: View {
    
    enum DisplayType {
        case largeStacked
        case smallInline(joinedOn: Date?)
    }
    
    let displayType: DisplayType
    let accountMetrics: MastodonAccount.Metrics?
    let onTapOfMetric: ((StatType)->())?
    
    var body: some View {
        HStack(spacing: doublePadding) {
            ForEach(stats(forDisplayType: displayType), id: \.self) { stat in
                statsView(stat)
                    .fixedSize()
                    .onTapGesture {
                        onTapOfMetric?(stat)
                    }
            }
            switch displayType {
            case .largeStacked:
                EmptyView()
            case .smallInline(let joinedDate):
                joinedOn(joinedDate)
                    .fixedSize()
            }
        }
        .font(.caption)
    }
    
    func stats(forDisplayType displayType: DisplayType) -> [StatType] {
        switch displayType {
        case .largeStacked:
            StatType.allCases
        case .smallInline:
            [.followersCount, .followingCount]
        }
    }
    
    @ViewBuilder func statsView(_ stat: StatType) -> some View {
        switch displayType {
        case .largeStacked:
            VStack(spacing: 0) {
                Text(MastodonMetricFormatter().string(from: statCount(stat)) ?? "-")
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(stat.label)
                    .font(.footnote)
                    .lineLimit(1)
            }
        case .smallInline:
            HStack(spacing: tinySpacing) {
                Text(MastodonMetricFormatter().string(from: statCount(stat)) ?? "-")
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(stat.label)
                    .lineLimit(1)
            }
        }
    }
    
    @ViewBuilder func joinedOn(_ joinedDate: Date?) -> some View {
        if let joinedDate {
            HStack(spacing: 0) {
                Text(L10n.Scene.Profile.Fields.joined)
                    .lineLimit(1)
                Text(" \(formattedJoinedDate(joinedDate))")
                    .lineLimit(1)
                    .fontWeight(.semibold)
            }
        }
    }
    
    func formattedJoinedDate(_ joinedDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: joinedDate)
    }
    
    func statCount(_ stat: StatType) -> Int {
        guard let accountMetrics else { return 0 }
        switch stat {
        case .postCount:
            return accountMetrics.postCount
        case .followingCount:
            return accountMetrics.followingCount
        case .followersCount:
            return accountMetrics.followersCount
        }
    }
    
    enum StatType: CaseIterable {
        case postCount
        case followingCount
        case followersCount
        
        var label: String {
            switch self {
            case .postCount:
                L10n.Scene.Profile.Dashboard.otherPosts
            case .followingCount:
                L10n.Scene.Profile.Dashboard.otherFollowing
            case .followersCount:
                L10n.Scene.Profile.Dashboard.otherFollowers
            }
        }
    }
}
