//
//  APIService+Block.swift
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
    
    private struct MastodonBlockContext {
        let sourceUserID: String
        let targetUserID: String
        let targetUsername: String
        let isBlocking: Bool
        let isFollowing: Bool
    }
    
    @discardableResult
    public func getBlocked(
        sinceID: Mastodon.Entity.Status.ID? = nil,
        limit: Int? = nil,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let response = try await Mastodon.API.Account.blocks(
            session: session,
            domain: authenticationBox.domain,
            sinceID: sinceID,
            limit: limit,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
    public func block(_ account: Mastodon.Entity.Account.ID, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.block(
            session: session,
            domain: authenticationBox.domain,
            accountID: account,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response.value
    }
    
    public func unblock(_ account: Mastodon.Entity.Account.ID, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.unblock(
            session: session,
            domain: authenticationBox.domain,
            accountID: account,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response.value
    }
    
}
