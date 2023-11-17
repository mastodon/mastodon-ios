//
//  APIService+Block.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import UIKit
import Combine
import MastodonSDK

extension APIService {
    
    private struct MastodonBlockContext {
        let sourceUserID: Mastodon.Entity.Account.ID
        let targetUserID: Mastodon.Entity.Account.ID
        let targetUsername: String
        let isBlocking: Bool
        let isFollowing: Bool
    }
    
    @discardableResult
    public func getBlocked(
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        try await _getBlocked(sinceID: nil, limit: nil, authenticationBox: authenticationBox)
    }
    
    private func _getBlocked(
        sinceID: Mastodon.Entity.Status.ID?,
        limit: Int?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let managedObjectContext = backgroundManagedObjectContext
        let response = try await Mastodon.API.Account.blocks(
            session: session,
            domain: authenticationBox.domain,
            sinceID: sinceID,
            limit: limit,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
    
        return response
    }
    
//    public func toggleBlock(
//        user: Mastodon.Entity.Account,
//        authenticationBox: MastodonAuthenticationBox
//    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
//        
////        let managedObjectContext = backgroundManagedObjectContext
////        let blockContext: MastodonBlockContext = try await managedObjectContext.performChanges {
////            let authentication = authenticationBox.authentication
////            
//            guard
////                let user = user.object(in: managedObjectContext),
//                let me = authenticationBox.inMemoryCache.meAccount,
//                let relationship = try await Mastodon.API.Account.relationships(
//                    session: session,
//                    domain: authenticationBox.domain,
//                    query: .init(ids: [user.id]),
//                    authorization: authenticationBox.userAuthorization
//                ).singleOutput().value.first
//            else {
//                throw APIError.implicit(.badRequest)
//            }
////
////            let isBlocking = user.blockingBy.contains(me)
////            let isFollowing = user.followingBy.contains(me)
////            // toggle block state
////            user.update(isBlocking: !isBlocking, by: me)
////            // update follow state implicitly
////            if !isBlocking {
////                // will do block action. set to unfollow
////                user.update(isFollowing: false, by: me)
////            }
////
////            return MastodonBlockContext(
////                sourceUserID: me.id,
////                targetUserID: user.id,
////                targetUsername: user.username,
////                isBlocking: isBlocking,
////                isFollowing: isFollowing
////            )
////        }
//        
//
//        
//        let blockContext = MastodonBlockContext(
//            sourceUserID: me.id,
//            targetUserID: user.id,
//            targetUsername: user.username,
//            isBlocking: !relationship.blocking,
//            isFollowing: {
//                if !relationship.blocking {
//                    return false
//                }
//                return relationship.following
//            }()
//        )
//        
//        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
//        do {
//            if blockContext.isBlocking {
//                let response = try await Mastodon.API.Account.unblock(
//                    session: session,
//                    domain: authenticationBox.domain,
//                    accountID: blockContext.targetUserID,
//                    authorization: authenticationBox.userAuthorization
//                ).singleOutput()
//                result = .success(response)
//            } else {
//                let response = try await Mastodon.API.Account.block(
//                    session: session,
//                    domain: authenticationBox.domain,
//                    accountID: blockContext.targetUserID,
//                    authorization: authenticationBox.userAuthorization
//                ).singleOutput()
//                result = .success(response)
//            }
//        } catch {
//            result = .failure(error)
//        }
//                
//        let response = try result.get()
//        return response
//    }

    public func toggleBlock(
        user: Mastodon.Entity.Account,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        guard let relationship = try await relationship(forAccounts: [user], authenticationBox: authenticationBox).value.first else {
            throw APIError.implicit(.badRequest)
        }

        let response: Mastodon.Response.Content<Mastodon.Entity.Relationship>

        if relationship.blocking {
            response = try await Mastodon.API.Account.unblock(
                session: session,
                domain: authenticationBox.domain,
                accountID: user.id,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
        } else {
            response = try await Mastodon.API.Account.block(
                session: session,
                domain: authenticationBox.domain,
                accountID: user.id,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()
        }

        return response
    }
}
