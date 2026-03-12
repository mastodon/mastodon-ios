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
        switch displayType {
        case .largeStacked:
            HStack(spacing: doublePadding) {
                contents
            }
            .font(.caption)
        case .smallInline:
            FlowLayout(maxItemWidth: 300, interItemSpacing: 20) {
                contents
            }
            .font(.caption)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder var contents: some View {
        ForEach(stats(forDisplayType: displayType), id: \.self) { stat in
            statsView(stat)
                .fixedSize()
                .onTapGesture {
                    onTapOfMetric?(stat)
                }
        }
    }
    
    func stats(forDisplayType displayType: DisplayType) -> [StatType] {
        switch displayType {
        case .largeStacked:
            [.postCount, .followersCount, .followingCount]
        case .smallInline:
            StatType.allCases
        }
    }
    
    @ViewBuilder func statsView(_ stat: StatType) -> some View {
        switch displayType {
        case .largeStacked:
            VStack(spacing: 0) {
                Text(statValue(stat))
                    .font(.headline)
                    .fontWeight(.semibold)
                Text(stat.label)
                    .font(.footnote)
                    .lineLimit(1)
            }
        case .smallInline:
            VStack(alignment: .leading, spacing: 0) {
                Text(stat.label)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
                Text(statValue(stat))
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }
        }
    }
    
    func formattedJoinedDate(_ joinedDate: Date) -> String {
        let joinedYear = Calendar.current.component(.year, from: joinedDate)
        let currentYear = Calendar.current.component(.year, from: .now)
        
        if joinedYear == currentYear {
            return joinedDate.formatted(.dateTime.month(.abbreviated).day())
        } else {
            return joinedDate.formatted(.dateTime.year())
        }
    }
    
    func statValue(_ stat: StatType) -> String {
        let unknownValue = "-"
        guard let accountMetrics else { return unknownValue }
        
        let count: Int
        switch stat {
        case .postCount:
            count = accountMetrics.postCount
        case .followingCount:
            count = accountMetrics.followingCount
        case .followersCount:
            count = accountMetrics.followersCount
        case .joinedOn:
            switch displayType {
            case .largeStacked:
                return unknownValue
            case .smallInline(let joinedOn):
                if let joinedOn {
                    return formattedJoinedDate(joinedOn)
                } else {
                    return unknownValue
                }
            }
        }
        return MastodonMetricFormatter().string(from: count) ?? unknownValue
    }
    
    enum StatType: CaseIterable {
        case postCount
        case followersCount
        case followingCount
        case joinedOn
        
        var label: String {
            // TODO: localization
            switch self {
            case .postCount:
                "Posts"
            case .followingCount:
                "Following"
            case .followersCount:
                "Followers"
            case .joinedOn:
                "Joined"
            }
        }
    }
}
