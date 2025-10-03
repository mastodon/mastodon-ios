// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonCore
import MastodonSDK
import SwiftUI

@MainActor
@Observable class AccountRowViewModel {
    private(set) var account: MastodonAccount
    private var relationshipViewModel = RelationshipViewModel()
    var actionHandler: MastodonPostMenuActionHandler?
    var relationshipButton: RelationshipButtonType = .updating
    nonisolated let id: Mastodon.Entity.Account.ID
    
    init(account: MastodonAccount) {
        self.account = account
        self.id = account.id
    }
    
    func prepareForDisplay(withRelationship relationship: MastodonAccount.Relationship) {
        relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: account.locked)
        relationshipButton = relationshipViewModel.button
    }
    
    func updateRelationship(_ updated: MastodonAccount.Relationship) {
        if relationshipViewModel.relationship?.refersToSameAccount(as: updated) == true {
            relationshipViewModel.prepareForDisplay(relationship: updated, theirAccountIsLocked: account.locked)
            relationshipButton = relationshipViewModel.button
        }
    }
    
    func updateAccount(_ updated: MastodonAccount) {
        account = updated
    }
    
    func doRelationshipButtonAction() async throws {
        if let action = relationshipViewModel.button.buttonAction.mastodonPostMenuAction {
            try await actionHandler?.doAction(action, forAccount: account)
        }
    }
    
    func goToProfile() {
        guard let relationship = relationshipViewModel.relationship else { return }
        switch relationship {
        case .isMe:
            let profile: ProfileViewController.ProfileType = .me(account._legacyEntity)
            actionHandler?.presentScene(.profile(profile), fromPost: nil, transition: .show)
        case .isNotMe(let relationshipInfo):
            guard let me = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount else { return }
            let profile: ProfileViewController.ProfileType = .notMe(me: me, displayAccount: account._legacyEntity, relationship: relationship.info?._legacyEntity)
            actionHandler?.presentScene(.profile(profile), fromPost: nil, transition: .show)
        }
    }
}
