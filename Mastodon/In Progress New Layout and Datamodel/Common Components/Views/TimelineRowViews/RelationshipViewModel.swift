// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonCore

@MainActor class RelationshipViewModel {
    var actionHandler: MastodonPostMenuActionHandler? = nil
    public var button: RelationshipButtonType = .updating
    public private(set) var relationship: MastodonAccount.Relationship? = nil
    
    public func prepareForDisplay(relationship: MastodonAccount.Relationship, theirAccountIsLocked: Bool) {
        self.relationship = relationship
        if let entity = relationship.info?._legacyEntity {
            let updatedButton = RelationshipButtonType(relationship: entity, theirAccountIsLocked: theirAccountIsLocked)
            button = updatedButton
        }
    }
    
    @MainActor
    func doRelationshipAction(
        _ action: RelationshipButtonType.RelationshipAction,
        account: MastodonAccount
    ) async throws {
        switch action {
        case .follow:
            try await actionHandler?.doAction(.follow, forAccount: account)
        case .unfollow:
            try await actionHandler?.doAction(.unfollow, forAccount: account)
        case .unmute:
            try await actionHandler?.doAction(.unmute, forAccount: account)
        case .unblock:
            try await actionHandler?.doAction(.unblockUser, forAccount: account)
        case .noAction:
            throw AppError.unexpected(
                "action attempted for relationship element that has no action"
            )
        }
    }
}
