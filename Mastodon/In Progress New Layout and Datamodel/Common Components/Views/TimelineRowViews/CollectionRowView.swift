// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import MastodonSDK
import MastodonUI
import SwiftUI
import MastodonCore

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
                
                HStack(alignment: .top) {
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
                    
                    viewModel.menuButton(isFullCollectionView: false, navigator: navigator, relationshipModel: viewModel.relationshipViewModel)
                }
                .frame(width: contentWidth)
            }
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
@MainActor public class CollectionViewModel {
    nonisolated let collection: Mastodon.Entity.Collection
    private(set) var relationshipViewModel = RelationshipViewModel()
    var authorHandle: String?
    var authorAccount: MastodonAccount?
    var accountAvatarUrls: [URL] = []
    
    init(collection: Mastodon.Entity.Collection) {
        self.collection = collection
    }
    
    @ViewBuilder func menuButton(isFullCollectionView: Bool, navigator: MastodonNavigationRouter, relationshipModel: RelationshipViewModel?) -> some View {
        Menu {
            let submenus = isFullCollectionView ? collectionMenuActions() : collectionRowMenuActions()
            ForEach(submenus, id: \.self.id) { submenu in
                ForEach(submenu.items, id: \.self) { menuAction in
                    switch menuAction {
                    case .miscellaneous:
                        EmptyView()
                    case .navigationalAction(let navAction):
                        let domainName: String? = {
                            guard let relationshipModel else { return nil }
                            switch relationshipModel.relationship {
                            case .isMe, .none:
                                return nil
                            case .isNotMe:
                                return self.authorAccount?.domain == AuthenticationServiceProvider.shared.currentActiveUser.value?.domain ? nil : self.authorAccount?.domain
                            }
                        }()
                        navigator.menuItem(navAction, notMyDomainName: domainName)
                    case .postAction:
                        EmptyView()
                    case .collectionAction(let action):
                        switch action {
                        case .reportCollection:
                            MastodonMenuAction.menuButton(systemImageName: nil, text: action.labelText) {
                                Task {
                                    do {
                                        try await self.doMenuAction(action)
                                    } catch {
                                        // TODO: implement error handling
                                    }
                                }
                            }
                        case .removeMyself:
                            MastodonMenuAction.menuButton(systemImageName: nil, text: action.labelText) {
                                Task {
                                    do {
                                        try await self.doMenuAction(action)
                                    } catch {
                                        // TODO: implement error handling
                                    }
                                }
                            }
                        }
                    case .relationshipAction(let relAction):
                        if let relationshipModel, let account = self.authorAccount {
                            relationshipModel.menuItem(relAction, forAccount: account, navigator: navigator)
                        } else {
                            EmptyView()
                        }
                    }
                }
                Divider()
            }
        } label: {
            Image(systemName: "ellipsis")
                .frame(width: 44, height: 44)
        }
    }
    
    func doMenuAction(_ action: MastodonMenuAction.CollectionMenuAction) async throws {
        switch action {
        case .reportCollection:
            // TODO: implement
            assertionFailure("reportCollection is not yet implemented")
        case .removeMyself:
            // TODO: implement
            assertionFailure("removeMyself is not yet implemented")
        }
    }
    
    func prepareForDisplay(withRelationship relationship: MastodonAccount.Relationship) {
        relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: authorAccount?.locked == true)
    }
    
    func updateAuthorAccount(_ updated: MastodonAccount) {
        authorAccount = updated
        authorHandle = updated.handle
    }
}

