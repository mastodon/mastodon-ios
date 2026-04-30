// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import MastodonSDK
import MastodonUI
import SwiftUI

struct CollectionRowView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator
    @Environment(CollectionViewModel.self) var viewModel
    let contentWidth: CGFloat
    
    let avatarViewSize = AvatarView.Size.extraSmall
    let avatarSize = AvatarSize.extraSmall
    
    var body: some View {
            VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content properly aligned with the gap between avatar and content
                HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                    
                    ZStack {
                        avatarsView
                            .blur(radius: viewModel.collection.sensitive == true ? 3 : 0)
                        if viewModel.collection.sensitive == true {
                            avatarViewSize.shape
                                .fill(Color(uiColor: .systemBackground))
                                .frame(width: avatarSize, height: avatarSize)
                            Image(systemName: "eye.slash")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .padding(3)
                                .frame(width: avatarSize)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.collection.name ?? "")
                            .fontWeight(.semibold)
                        if let author = viewModel.authorHandle {
                            Text("by \(author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(viewModel.collection.itemCount) accounts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .alignmentGuide(.gutterAlign) { d in
                        return d[HorizontalAlignment.leading]
                    }
                    
                    Image(systemName: "ellipsis")
                }
                .frame(width: contentWidth)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
    
    let avatarSpacing: CGFloat = 2
    @ViewBuilder var avatarsView: some View {
        VStack(spacing: avatarSpacing) {
            HStack(spacing: avatarSpacing) {
                avatar(atIndex: 0)
                avatar(atIndex: 1)
            }
            HStack(spacing: avatarSpacing) {
                avatar(atIndex: 2)
                avatar(atIndex: 3)
            }
        }
    }
    
    @ViewBuilder func avatar(atIndex index: Int) -> some View {
        if index < viewModel.accountAvatarUrls.count {
            let url = viewModel.accountAvatarUrls[index]
            AvatarView(size: avatarViewSize, avatarSource: .url(url), goToProfile: nil)
                .frame(width: avatarSize, height: avatarSize)
                .accessibilityHidden(true)
        } else {
            avatarViewSize.shape
                .fill(.secondary)
                .frame(width: avatarSize, height: avatarSize)
        }
    }
}

@Observable
@MainActor class CollectionViewModel {
    nonisolated let collection: Mastodon.Entity.Collection
    var authorHandle: String? 
    var accountAvatarUrls: [URL] = []
    
    init(collection: Mastodon.Entity.Collection) {
        self.collection = collection
    }
}

