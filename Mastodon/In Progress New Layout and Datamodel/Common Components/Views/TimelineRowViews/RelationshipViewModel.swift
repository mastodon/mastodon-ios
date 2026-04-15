// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import MastodonCore
import SwiftUI

@MainActor
@Observable class RelationshipViewModel {
    var actionHandler: MastodonPostMenuActionHandler? = nil
    public private(set) var button: RelationshipButtonType = .updating
    public private(set) var relationship: MastodonAccount.Relationship? = nil
    public var personalNoteEditingState: ProfileView.PersonalNoteEditState?
    private var theirAccountIsLocked: Bool?
    public var pendingRequestToFollowMe: Bool = true
    
    public func prepareForDisplay(relationship: MastodonAccount.Relationship, theirAccountIsLocked: Bool) {
        self.theirAccountIsLocked = theirAccountIsLocked
        self.relationship = relationship
        switch relationship {
        case .isNotMe(let info):
            guard let entity = info?._legacyEntity else { break }
            let updatedButton = RelationshipButtonType(relationship: entity, theirAccountIsLocked: theirAccountIsLocked)
            button = updatedButton
        case .isMe:
            button = .edit
        }
    }
    
    public func updateForDomainBlockChange(isBlocked: Bool) {
        guard let relationship, let theirAccountIsLocked else { return }
        let updatedRelationship = relationship.byUpdatingDomainBlock(isBlocked: isBlocked)
        prepareForDisplay(relationship: updatedRelationship, theirAccountIsLocked: theirAccountIsLocked)
    }
    
    @MainActor
    func doRelationshipAction(
        _ action: RelationshipButtonType.RelationshipAction,
        account: MastodonAccount,
        navigator: MastodonNavigationRouter
    ) async throws {
        let currentState = button
        do {
            button = .updating
            switch action {
            case .editProfile:
                throw AppError.unexpected(
                    "editProfile action cannot be handled by the RelationshipViewModel"
                )
            case .follow:
                try await doMenuAction(.follow, forAccount: account, navigator: navigator)
            case .unfollow:
                try await doMenuAction(.unfollow, forAccount: account, navigator: navigator)
            case .unmute:
                try await doMenuAction(.unmute, forAccount: account, navigator: navigator)
            case .unblock:
                try await doMenuAction(.unblockUser, forAccount: account, navigator: navigator)
            case .noAction:
                throw AppError.unexpected(
                    "action attempted for relationship element that has no action"
                )
            }
        } catch {
            button = currentState
            throw error
        }
    }
}
