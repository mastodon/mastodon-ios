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
    let includeMenu: Bool
    
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
                            Text(L10nLookup.Scene.Collections.authorLabel(author))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(L10nLookup.Scene.Collections.numberOfAccounts(viewModel.itemCount))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .alignmentGuide(.gutterAlign) { d in
                        return d[HorizontalAlignment.leading]
                    }
                    
                    if includeMenu {
                        viewModel.menuButton(isFullCollectionView: false, navigator: navigator, relationshipModel: viewModel.relationshipViewModel)
                    }
                }
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
            AvatarView(style: .roundedRect, size: avatarViewSize, avatarSource: .url(url))
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
    let id: Mastodon.Entity.Collection.ID
    var collection: Mastodon.Entity.Collection
    private(set) var relationshipViewModel = RelationshipViewModel()
    var authorHandle: String?
    var authorAccount: MastodonAccount?
    private var partialAccounts: [AccountInfo] = []
    var accountAvatarUrls: [URL] = []
    var iHaveRemovedMyself = false
    
    var itemCount: Int {
        if iHaveRemovedMyself {
            return collection.itemCount - 1
        } else {
            return collection.itemCount
        }
    }
    
    init(collection: Mastodon.Entity.Collection) {
        self.id = collection.id
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
                                        try await self.doMenuAction(action, navigator: navigator)
                                    } catch {
                                        navigator.didReceiveError(error)
                                    }
                                }
                            }
                        case .removeMyself:
                            if !self.iHaveRemovedMyself {
                                MastodonMenuAction.menuButton(systemImageName: nil, text: action.labelText) {
                                    Task {
                                        do {
                                            try await self.doMenuAction(action, navigator: navigator)
                                        } catch {
                                            navigator.didReceiveError(error)
                                        }
                                    }
                                }
                            } else {
                                EmptyView()
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
                .frame(width: 44, height: 44, alignment: .topTrailing)
        }
    }
    
    func doMenuAction(_ action: MastodonMenuAction.CollectionMenuAction, navigator: MastodonNavigationRouter) async throws {
        switch action {
        case .reportCollection:
            guard let relationship = relationshipViewModel.relationship, let account = authorAccount else { return }
            guard let reportViewModel = account.reportViewModel(withCollection: collection, relationship: relationship) else { return }
            navigator.presentSheet(.report(reportViewModel), afterDeconflictionDelay: true)
        case .removeMyself:
            if let meItem = collection.items.first(where: { $0.account_id == AuthenticationServiceProvider.shared.currentActiveUser.value?.userID }) {
                doRemoveMe(meItemID: meItem.id, navigator: navigator)
            }
        }
    }
    
    func prepareForDisplay(withRelationship relationship: MastodonAccount.Relationship) {
        relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: authorAccount?.locked == true)
    }
    
    func updateCollection(_ collection: Mastodon.Entity.Collection) {
        assert(collection.id == id, "Attempting to update a CollectionViewModel with a collection with a different ID will produce unexpected results.")
        self.collection = collection
        updateAvatarUrls(nil)
    }
    
    func updateAuthorAccount(_ updated: MastodonAccount) {
        authorAccount = updated
        authorHandle = "@" + updated.handle
    }
    
    func updateAvatarUrls(_ updatedPartialAccounts: [AccountInfo]?) {
        if let updatedPartialAccounts {
            partialAccounts = updatedPartialAccounts
        }
        let firstFourAvatars = collection.items.compactMap({ member -> URL? in
            guard !iHaveRemovedMyself || member.account_id != AuthenticationServiceProvider.shared.currentActiveUser.value?.userID else { return nil }
            guard let partialAccount = partialAccounts.first(where: { $0.id ==  member.account_id }) else { return nil }
            return partialAccount.avatarURL
        }).prefix(4)
        accountAvatarUrls = Array(firstFourAvatars)
    }
    
    func doRemoveMe(meItemID: Mastodon.Entity.CollectionMember.ID, navigator: MastodonNavigationRouter) {
        navigator.activeAlert = .confirmRemoveMeFromCollection(collectionName: collection.name ?? "Collection", didConfirm: { confirmed in
            if confirmed {
                Task {
                    do {
                        try await self.commitRemoveMe(meItemID: meItemID)
                    } catch {
                        navigator.didReceiveError(error)
                    }
                }
            }
        })
    }
    
    func commitRemoveMe(meItemID: Mastodon.Entity.CollectionMember.ID) async throws {
        guard let authBox = AuthenticationServiceProvider.shared.currentActiveUser.value else { return }
        try await APIService.shared.removeFromCollection(collectionId: collection.id, collectionMemberId: meItemID, authenticationBox: authBox)
        didFinishRemovingMyself()
    }
    
    private func didFinishRemovingMyself() {
        withAnimation {
            self.iHaveRemovedMyself = true
            self.updateAvatarUrls(nil)
        }
    }
}

extension Mastodon.Entity.PartialAccountWithAvatar {
    @MainActor var fullHandle: String {
        let acctSplitOnAt = acct.split(separator: "@")
        if acctSplitOnAt.count == 1, let domain = AuthenticationServiceProvider.shared.currentActiveUser.value?.domain {
            return acct + "@" + domain
        } else {
            return acct
        }
    }
}
