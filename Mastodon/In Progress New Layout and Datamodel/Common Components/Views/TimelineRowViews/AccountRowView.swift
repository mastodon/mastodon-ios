// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import MastodonSDK
import MastodonUI
import SwiftUI

struct AccountRowView: View {
    let account: MastodonAccount
    let contentWidth: CGFloat
  
    var body: some View {
        VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content properly aligned with the gap between avatar and content
            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                AvatarView(size: .large, authorAvatarUrl: account.avatarURL, goToProfile: nil)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 0) {
                    authorDisplayName
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .alignmentGuide(.gutterAlign) { d in
                            return d[HorizontalAlignment.leading]
                        }
                    Text("@\(account.handle)")
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let verifiedLink = account.metadata.verifiedLink {
                        HStack(spacing: 0) {
                            Image(systemName: "checkmark")
                                .font(.subheadline)
                                .foregroundStyle(.link)
                            MastodonContentView.verifiedLink(html: verifiedLink)
                        }
                    }
                    
                    Spacer()
                    
                    HStack(spacing: doublePadding) {
                        ForEach(StatType.allCases, id: \.self) { stat in
                            statsView(stat)
                        }
                        Spacer()
                        Button("FOLLOW") {
                            
                        }//.buttonStyle(FollowButton(.iDoNotFollowThem(theirAccountIsLocked: false)))
                    }
                }
                .frame(width: contentWidth)
            }
        }
        .padding(.trailing)
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder var authorDisplayName: some View {
        MastodonContentView.header(html: account.displayInfo.displayName, emojis: account.displayInfo.emojis, style: .author(isInlinePreview: false))
    }
    
    @ViewBuilder func statsView(_ stat: StatType) -> some View {
        VStack(spacing: 0) {
            Text(MastodonMetricFormatter().string(from: statCount(stat)) ?? "-")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(stat.label)
                .font(.footnote)
        }
    }
    
    func statCount(_ stat: StatType) -> Int {
        switch stat {
        case .postCount:
            return account.metrics.postCount
        case .followingCount:
            return account.metrics.followingCount
        case .followersCount:
            return account.metrics.followersCount
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
