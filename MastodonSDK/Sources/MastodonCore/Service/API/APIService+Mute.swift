//
//  APIService+Mute.swift
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
    
    private struct MastodonMuteContext {
        let sourceUserID: Mastodon.Entity.Account.ID
        let targetUserID: Mastodon.Entity.Account.ID
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
    
    public func toggleMute(
        user: Mastodon.Entity.Account,
        authenticationBox: MastodonAuthenticationBox,
        isMuting: Bool
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {

        let managedObjectContext = backgroundManagedObjectContext
        let me = authenticationBox.authentication.user
        
        let muteContext: MastodonMuteContext = MastodonMuteContext(
            sourceUserID: me.id,
            targetUserID: user.id,
            targetUsername: user.username,
            isMuting: isMuting
        )
        
        let result: Result<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>
        do {
            if muteContext.isMuting {
                let response = try await Mastodon.API.Account.unmute(
                    session: session,
                    domain: authenticationBox.domain,
                    accountID: muteContext.targetUserID,
                    authorization: authenticationBox.userAuthorization
                ).singleOutput()
                try await getMutes(authenticationBox: authenticationBox)
                result = .success(response)
            } else {
                let response = try await Mastodon.API.Account.mute(
                    session: session,
                    domain: authenticationBox.domain,
                    accountID: muteContext.targetUserID,
                    authorization: authenticationBox.userAuthorization
                ).singleOutput()
                try await getMutes(authenticationBox: authenticationBox)
                result = .success(response)
            }
        } catch {
            result = .failure(error)
        }

        let response = try result.get()
        return response
    }
    
}

