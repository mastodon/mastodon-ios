// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import MastodonSDK
import MastodonUI
import SwiftUI

struct AccountRowView: View {
    @Environment(AccountRowViewModel.self) var viewModel
    let contentWidth: CGFloat
  
    var body: some View {
        VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content properly aligned with the gap between avatar and content
            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                AvatarView(size: .large, authorAvatarUrl: viewModel.account.avatarURL, goToProfile: nil)
                    .accessibilityHidden(true)
                
                VStack(alignment: .leading, spacing: 0) {
                    authorDisplayName
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .alignmentGuide(.gutterAlign) { d in
                            return d[HorizontalAlignment.leading]
                        }
                    Text("@\(viewModel.account.handle)")
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    if let verifiedLink = viewModel.account.metadata.verifiedLink {
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
                        viewModel.relationshipButton.button {
                            Task {
                                try await viewModel.doRelationshipButtonAction()
                            }
                        }
                    }
                }
                .frame(width: contentWidth)
            }
        }
        .padding(.trailing)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder var authorDisplayName: some View {
        MastodonContentView.header(html: viewModel.account.displayInfo.displayName, emojis: viewModel.account.displayInfo.emojis, style: .author(isInlinePreview: false))
    }
    
    @ViewBuilder func statsView(_ stat: StatType) -> some View {
        VStack(spacing: 0) {
            Text(MastodonMetricFormatter().string(from: statCount(stat)) ?? "-")
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(stat.label)
                .font(.footnote)
                .lineLimit(1)
        }
    }
    
    func statCount(_ stat: StatType) -> Int {
        switch stat {
        case .postCount:
            return viewModel.account.metrics.postCount
        case .followingCount:
            return viewModel.account.metrics.followingCount
        case .followersCount:
            return viewModel.account.metrics.followersCount
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
