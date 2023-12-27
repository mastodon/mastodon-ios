//
//  APIService+Follow.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {

    private struct MastodonFollowContext {
        let sourceUserID: String
        let targetUserID: String
        let isFollowing: Bool
        let isPending: Bool
        let needsUnfollow: Bool
    }
    
    /// Toggle friendship between target MastodonUser and current MastodonUser
    ///
    /// Following / Following pending <-> Unfollow
    ///
    /// - Parameters:
    ///   - mastodonUser: target MastodonUser
    ///   - activeMastodonAuthenticationBox: `AuthenticationService.MastodonAuthenticationBox`
    /// - Returns: publisher for `Relationship`
    public func toggleFollow(
        account: Mastodon.Entity.Account,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {

        guard let relationship = try await relationship(forAccounts: [account], authenticationBox: authenticationBox).value.first else {
            throw APIError.implicit(.badRequest)
        }

        let response: Mastodon.Response.Content<Mastodon.Entity.Relationship>

        if relationship.following || (relationship.requested ?? false) {
            // unfollow
            response = try await Mastodon.API.Account.unfollow(
                session: session,
                domain: authenticationBox.domain,
                accountID: account.id,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
        } else {
            response = try await Mastodon.API.Account.follow(
                session: session,
                domain: authenticationBox.domain,
                accountID: account.id,
                followQueryType: .follow(query: .init()),
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
        }

        return response
    }

    public func toggleShowReblogs(
      for user: Mastodon.Entity.Account,
      authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let relationship = try await Mastodon.API.Account.relationships(
            session: session,
            domain: authenticationBox.domain,
            query: .init(ids: [user.id]),
            authorization: authenticationBox.userAuthorization
        ).singleOutput().value.first

        let oldShowReblogs = relationship?.showingReblogs ?? true
        let newShowReblogs = (oldShowReblogs == false)

        let response = try await Mastodon.API.Account.follow(
            session: session,
            domain: authenticationBox.domain,
            accountID: user.id,
            followQueryType: .follow(query: .init(reblogs: newShowReblogs)),
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }
}
