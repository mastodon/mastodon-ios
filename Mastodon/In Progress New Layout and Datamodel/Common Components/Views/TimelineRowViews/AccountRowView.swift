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
    let collectionViewModel: CollectionViewModel?
  
    var body: some View {
        VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content properly aligned with the gap between avatar and content
            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                AvatarView(style: .roundedRect, size: .large, avatarSource: .url(viewModel.account.avatarURL))
                    .accessibilityHidden(true)
                    .onAsyncTap {
                        navigator.push(.profile(account: viewModel.account._legacyEntity, relationship: viewModel.myRelationship))
                    } onError: { error in
                        navigator.didReceiveError(error)
                    }
            
                VStack(alignment: .leading, spacing: 0) {
                    AccountDisplayNameAndHandle(account: viewModel.account, includeVerifiedLink: true)
                    
                    Spacer()
                    
                    HStack(spacing: doublePadding) {
                        AccountStatsView(displayType: .largeStacked, accountMetrics: viewModel.account.metrics, onTapOfMetric: nil)
                        Spacer()
                        viewModel.relationshipButton.button(isOpaque: false, isInCollection: collectionViewModel != nil) {
                            Task {
                                if let collectionViewModel {
                                    if let meItem = collectionViewModel.collection.items.first(where: { $0.account_id == viewModel.account.id }) {
                                        collectionViewModel.doRemoveMe(meItemID: meItem.id, navigator: navigator)
                                    }
                                } else {
                                    try await viewModel.doRelationshipButtonAction(navigator: navigator, isInCollection: false)
                                }
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
}

struct AccountDisplayNameAndHandle: View {
    let account: MastodonAccount
    let includeVerifiedLink: Bool
    
    var body: some View {
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
            if includeVerifiedLink, let verifiedLink = account.metadata.verifiedLink {
                HStack(spacing: 0) {
                    Image(systemName: "checkmark")
                        .font(.subheadline)
                        .foregroundStyle(.link)
                    MastodonContentView.verifiedLink(html: verifiedLink)
                }
            }
        }
    }
    
    @ViewBuilder var authorDisplayName: some View {
        MastodonContentView.header(html: account.displayInfo.displayName, emojis: account.displayInfo.emojis, style: .author(isInlinePreview: false))
    }
}
