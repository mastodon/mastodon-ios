// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import MastodonAsset
import MastodonLocalization
import MastodonSDK
import MastodonUI
import SwiftUI
import MastodonCore

struct CollectionRowView: View {
    @Environment(MastodonNavigationRouter.self) private var navigator: MastodonNavigationRouter?
    @Environment(CollectionViewModel.self) var viewModel
    let contentWidth: CGFloat
    let includeMenu: Bool
    var didChangeCollection: ((CollectionChange) -> Void)? = nil
    
    let avatarSize = AvatarSize.extraSmall
    
    var body: some View {
        VStack(alignment: .gutterAlign, spacing: 0) {  // gutterAlign keeps the content properly aligned with the gap between avatar and content
            HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
                
                ZStack {
                    avatarsView
                        .blur(radius: viewModel.collection.sensitive == true ? 3 : 0)
                    if viewModel.collection.sensitive == true {
                        Circle()
                            .fill(Color(uiColor: .systemBackground))
                            .frame(width: avatarSize.rawValue, height: avatarSize.rawValue)
                        Image(systemName: "eye.slash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(3)
                            .frame(width: avatarSize.rawValue)
                            .accessibilityLabel(L10nLookup.Scene.Collections.sensitiveContentHeading)
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
                    
                    if includeMenu, let navigator {
                        viewModel.menuButton(isFullCollectionView: false, navigator: navigator, relationshipModel: viewModel.relationshipViewModel, didChangeCollection: didChangeCollection)
                            .accessibilityHidden(true)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if includeMenu, let navigator {
                ForEach(viewModel.collectionMenuActions().flatMap(\.items), id: \.self) { menuAction in
                    viewModel.menuItem(menuAction, navigator: navigator, relationshipModel: viewModel.relationshipViewModel, didChangeCollection: didChangeCollection)
                }
            }
        }
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
            AvatarView(style: .circular, size: avatarSize, avatarSource: .url(url))
                .frame(width: avatarSize.rawValue, height: avatarSize.rawValue)
                .accessibilityHidden(true)
        } else {
            Circle()
                .fill(.secondary)
                .frame(width: avatarSize.rawValue, height: avatarSize.rawValue)
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
    private var removedMyItemID: Mastodon.Entity.CollectionMember.ID?
    var iHaveRemovedMyself: Bool {
        guard let removedMyItemID else { return false }
        return collection.items.contains { $0.id == removedMyItemID }
    }
    @ObservationIgnored private var isPreparingEditFlow = false
    private(set) var isDeleted = false
    
    var displayedItems: [Mastodon.Entity.CollectionMember] {
        collection.items.filter { $0.state != .pending && $0.id != removedMyItemID }
    }

    var itemCount: Int {
        displayedItems.count
    }
    
    init(collection: Mastodon.Entity.Collection) {
        self.id = collection.id
        self.collection = collection
    }
    
    @ViewBuilder func menuButton(isFullCollectionView: Bool, navigator: MastodonNavigationRouter, relationshipModel: RelationshipViewModel?, didChangeCollection: ((CollectionChange) -> Void)? = nil) -> some View {
        Menu {
            ForEach(collectionMenuActions(), id: \.self.id) { submenu in
                ForEach(submenu.items, id: \.self) { menuAction in
                    self.menuItem(menuAction, navigator: navigator, relationshipModel: relationshipModel, didChangeCollection: didChangeCollection)
                }
                Divider()
            }
        } label: {
            if isFullCollectionView {
                Image(systemName: "ellipsis")
            } else {
                Image(systemName: "ellipsis")
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
        }
    }
    
    @ViewBuilder func menuItem(_ menuAction: MastodonMenuAction, navigator: MastodonNavigationRouter, relationshipModel: RelationshipViewModel?, didChangeCollection: ((CollectionChange) -> Void)?) -> some View {
        switch menuAction {
        case .miscellaneous(let action):
            switch action {
            case .copyLink:
                MastodonMenuAction.menuButton(systemImageName: action.iconSystemName, text: action.labelText) {
                    UIPasteboard.general.string = self.collection.url
                }
            }
        case .share(let urlString):
            if let url = URL(string: urlString) {
                ShareLink(item: url) {
                    Label(L10nLookup.Scene.Collections.shareCollection, systemImage: "square.and.arrow.up")
                }
            }
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
            case .reportCollection, .manageAccounts, .editDetails, .deleteCollection:
                MastodonMenuAction.menuButton(systemImageName: nil, text: action.labelText, role: action.isDestructive ? .destructive : nil) {
                    Task {
                        do {
                            try await self.doMenuAction(action, navigator: navigator, didChangeCollection: didChangeCollection)
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
    
    func doMenuAction(_ action: MastodonMenuAction.CollectionMenuAction, navigator: MastodonNavigationRouter, didChangeCollection: ((CollectionChange) -> Void)? = nil) async throws {
        switch action {
        case .reportCollection:
            guard let relationship = relationshipViewModel.relationship, let account = authorAccount else { return }
            guard let reportViewModel = account.reportViewModel(withCollection: collection, relationship: relationship) else { return }
            navigator.presentSheet(.report(reportViewModel), afterDeconflictionDelay: true)
        case .removeMyself:
            if let meItem = collection.items.first(where: { $0.account_id == AuthenticationServiceProvider.shared.currentActiveUser.value?.userID }) {
                doRemoveMe(meItemID: meItem.id, navigator: navigator)
            }
        case .manageAccounts:
            try await pushEditFlow(step: .addAccounts, navigator: navigator, didChangeCollection: didChangeCollection)
        case .editDetails:
            try await pushEditFlow(step: .details, navigator: navigator, didChangeCollection: didChangeCollection)
        case .deleteCollection:
            confirmDelete(navigator: navigator, didChangeCollection: didChangeCollection)
        }
    }
    
    func pushEditFlow(step: CreateCollectionStep, navigator: MastodonNavigationRouter, didChangeCollection: ((CollectionChange) -> Void)?) async throws {
        guard !isPreparingEditFlow, let authenticationBox = navigator.authenticationBox else { return }
        isPreparingEditFlow = true
        defer { isPreparingEditFlow = false }
        let freshlyFetchedCollection = try await APIService.shared.collection(id: id, authenticationBox: authenticationBox).value
        let editModel = CreateCollectionViewModel(authBox: authenticationBox, editing: freshlyFetchedCollection, didChangeCollection: { didChangeCollection?(.edited) }, didReceiveError: { [weak navigator] error in navigator?.didReceiveError(error) })
        navigator.push(.collectionEditor(editModel, step: step))
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
        let firstFourAvatars = displayedItems.compactMap({ member -> URL? in
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
        try await APIService.shared.removeFromCollection(collectionID: collection.id, collectionMemberID: meItemID, authenticationBox: authBox)
        didFinishRemovingMyself(meItemID: meItemID)
    }
    
    private func didFinishRemovingMyself(meItemID: Mastodon.Entity.CollectionMember.ID) {
        withAnimation {
            self.removedMyItemID = meItemID
            self.updateAvatarUrls(nil)
        }
    }
    
    private func confirmDelete(navigator: MastodonNavigationRouter, didChangeCollection: ((CollectionChange) -> Void)?) {
        guard let authenticationBox = navigator.authenticationBox else { return }
        navigator.activeAlert = .confirmDeleteCollection(collectionName: collection.name ?? "", didConfirm: { confirmed in
            guard confirmed else { return }
            Task {
                do {
                    try await self.commitDelete(authenticationBox: authenticationBox)
                    didChangeCollection?(.deleted)
                } catch {
                    navigator.didReceiveError(error)
                }
            }
        })
    }
    
    private func commitDelete(authenticationBox: MastodonAuthenticationBox) async throws {
        try await APIService.shared.deleteCollection(collectionID: id, authenticationBox: authenticationBox)
        isDeleted = true
    }
}

enum CollectionChange {
    case edited
    case deleted
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
