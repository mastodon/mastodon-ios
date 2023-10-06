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
        let sourceUserID: MastodonUser.ID
        let targetUserID: MastodonUser.ID
        let isFollowing: Bool
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
        user: Mastodon.Entity.Account,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let authentication = authenticationBox.authentication
        let me = authentication.user
        
        let otherUser = try await Mastodon.API.Account.followers(
            session: session,
            domain: authentication.domain,
            userID: user.id,
            query: .init(maxID: nil, limit: nil),
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let isFollowing = otherUser.value.contains(me)
        
        let followContext = MastodonFollowContext(
            sourceUserID: me.id,
            targetUserID: user.id,
            isFollowing: isFollowing,
            needsUnfollow: isFollowing
        )
        
        // request follow or unfollow
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
        do {
            let response = try await Mastodon.API.Account.follow(
                session: session,
                domain: authenticationBox.domain,
                accountID: followContext.targetUserID,
                followQueryType: followContext.needsUnfollow ? .unfollow : .follow(query: .init()),
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
            result = .success(response)
        } catch {
            result = .failure(error)
        }

        let response = try result.get()
        return response
    }

    public func toggleShowReblogs(
        for user: Mastodon.Entity.Account,
      authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let me = authenticationBox.authentication.user
        
        let relationship = try await Mastodon.API.Account.relationships(
            session: session,
            domain: authenticationBox.domain,
            query: .init(ids: [user.id]),
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        let oldShowReblogs = relationship.value.first?.showingReblogs ?? false
        let newShowReblogs = !oldShowReblogs

        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>

        do {
            let response = try await Mastodon.API.Account.follow(
                session: session,
                domain: authenticationBox.domain,
                accountID: user.id,
                followQueryType: .follow(query: .init(reblogs: newShowReblogs)),
                authorization: authenticationBox.userAuthorization
            ).singleOutput()

            result = .success(response)
        } catch {
            result = .failure(error)
        }

        return try result.get()
    }
}
