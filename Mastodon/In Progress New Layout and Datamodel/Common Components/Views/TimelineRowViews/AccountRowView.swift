// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import MastodonSDK
import MastodonUI
import SwiftUI

struct AccountRowView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(AccountRowViewModel.self) var viewModel
    let contentWidth: CGFloat
  
    var body: some View {
        VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content properly aligned with the gap between avatar and content
            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                AvatarView(size: .large, avatarSource: .url(viewModel.account.avatarURL), goToProfile: { viewModel.goToProfile(navigator: navigator) })
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
                        AccountStatsView(displayType: .largeStacked, accountMetrics: viewModel.account.metrics, onTapOfMetric: nil)
                        Spacer()
                        viewModel.relationshipButton.button {
                            Task {
                                try await viewModel.doRelationshipButtonAction(navigator: navigator)
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
}
