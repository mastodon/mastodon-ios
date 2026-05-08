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
    var accountFollowsMe: Bool? {
        switch relationshipViewModel.relationship {
        case .isMe, .none:
            nil
        case .isNotMe(let info):
            info?.theyFollowMe
        }
    }
    nonisolated let id: Mastodon.Entity.Account.ID
    
    init(account: MastodonAccount) {
        self.account = account
        self.id = account.id
    }
    
    func prepareForDisplay(withRelationship relationship: MastodonAccount.Relationship) {
        relationshipViewModel.prepareForDisplay(relationship: relationship, theirAccountIsLocked: account.locked)
        relationshipButton = relationshipViewModel.button
    }
    
    func updateAccount(_ updated: MastodonAccount) {
        account = updated
    }
    
    func doRelationshipButtonAction(navigator: MastodonNavigationRouter, isInCollection: Bool) async throws {
        if let action = relationshipViewModel.button.buttonAction(isInCollection: isInCollection).mastodonRelationshipMenuAction {
            try await relationshipViewModel.doMenuAction(action, forAccount: account, navigator: navigator)
        }
    }
    
    func goToProfile(navigator: MastodonNavigationRouter) {
        navigator.push(.profile(account: account._legacyEntity, relationship: relationshipViewModel.relationship))
    }
}

extension AccountRowViewModel: FeedCoordinatorUpdatable {
    func incorporateUpdate(_ update: UpdatedElement) {
        switch update {
        case .hashtag, .deletedPost, .post:
            break
        case .relationship(let updated):
            if relationshipViewModel.relationship?.refersToSameAccount(as: updated) == true {
                relationshipViewModel.prepareForDisplay(relationship: updated, theirAccountIsLocked: account.locked)
                relationshipButton = relationshipViewModel.button
            }
        case .domainBlockChange(let domain, let isBlocked):
            guard account.domain == domain else { return }
            relationshipViewModel.updateForDomainBlockChange(isBlocked: isBlocked)
        }
    }
}
