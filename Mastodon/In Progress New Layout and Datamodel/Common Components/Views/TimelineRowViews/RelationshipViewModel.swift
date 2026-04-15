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
    public var pendingRequestToFollowMe: Bool = false
    
    public func prepareForDisplay(relationship: MastodonAccount.Relationship, theirAccountIsLocked: Bool) {
        self.theirAccountIsLocked = theirAccountIsLocked
        self.relationship = relationship
        switch relationship {
        case .isNotMe(let info):
            guard let entity = info?._legacyEntity else { break }
            let updatedButton = RelationshipButtonType(relationship: entity, theirAccountIsLocked: theirAccountIsLocked)
            button = updatedButton
            withAnimation {
                pendingRequestToFollowMe = info?.theyHaveRequestedToFollowMe ?? false
            }
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
                
            case .approveFollowRequest:
                try await doAnswerFollowRequest(true)
                
            case .rejectFollowRequest:
                try await doAnswerFollowRequest(false)
            }
        } catch {
            button = currentState
            throw error
        }
    }
    
    private func doAnswerFollowRequest(_ accept: Bool) async throws {
        guard let accountID = relationship?.info?.id,
              let authBox = AuthenticationServiceProvider.shared.currentActiveUser
            .value
        else { return }
        let expectedFollowedByResult = accept
        let newRelationship = try await APIService.shared.followRequest(
            userID: accountID,
            query: accept ? .accept : .reject,
            authenticationBox: authBox
        ).value
        assert(newRelationship.followedBy == expectedFollowedByResult, "expected to update following relationship after answering follow request")
        let newInfo = MastodonAccount.RelationshipInfo.init(newRelationship, fetchedAt: .now)
        FeedCoordinator.shared.publishUpdate(.relationship(.isNotMe(newInfo)))
    }
}
