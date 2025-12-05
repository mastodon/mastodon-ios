// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonLocalization
import MastodonUI
import SwiftUI

struct AccountStatsView: View {
    
    let accountMetrics: MastodonAccount.Metrics?
    let onTapOfMetric: ((StatType)->())?
    
    var body: some View {
        HStack(spacing: doublePadding) {
            ForEach(StatType.allCases, id: \.self) { stat in
                statsView(stat)
                    .onTapGesture {
                        onTapOfMetric?(stat)
                    }
            }
        }
    }
    
    @ViewBuilder func statsView(_ stat: StatType) -> some View {
        VStack(spacing: 0) {
            Text(MastodonMetricFormatter().string(from: statCount(stat)) ?? "-")
                .font(.headline)
                .fontWeight(.semibold)
            Text(stat.label)
                .font(.footnote)
                .lineLimit(1)
        }
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
