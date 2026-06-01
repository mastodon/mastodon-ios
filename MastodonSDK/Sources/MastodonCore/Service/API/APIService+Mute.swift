//
//  APIService+Mute.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import UIKit
import Combine
import MastodonSDK

extension APIService {
    
    private struct MastodonMuteContext {
        let targetUserID: String
        let targetUsername: String
        let isMuting: Bool
    }
    
    @discardableResult
    public func getMutes(
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        try await _getMutes(sinceID: nil, limit: nil, authenticationBox: authenticationBox)
    }
    
    private func _getMutes(
        sinceID: Mastodon.Entity.Status.ID?,
        limit: Int?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let response = try await Mastodon.API.Account.mutes(
            session: session,
            domain: authenticationBox.domain,
            sinceID: sinceID,
            limit: limit,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
    public func mute(_ accountID: Mastodon.Entity.Account.ID, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.mute(
            session: session,
            domain: authenticationBox.domain,
            accountID: accountID,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        return response.value
    }
    
    public func unmute(_ accountID: Mastodon.Entity.Account.ID, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        let response = try await Mastodon.API.Account.unmute(
            session: session,
            domain: authenticationBox.domain,
            accountID: accountID,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        return response.value
    }
    

}

