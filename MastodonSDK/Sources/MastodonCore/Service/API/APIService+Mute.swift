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
        let managedObjectContext = backgroundManagedObjectContext
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
        authenticationBox: MastodonAuthenticationBox,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {

        guard let relationship = try await Mastodon.API.Account.relationships(
            session: session,
            domain: authenticationBox.domain,
            query: .init(ids: [account.id]),
            authorization: authenticationBox.userAuthorization
        ).singleOutput().value.first else { throw APIError.implicit(.badRequest) }

        let muteContext = MastodonMuteContext(
            targetUserID: account.id,
            targetUsername: account.username,
            isMuting: relationship.muting
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

                result = .success(response)
            } else {
                let response = try await Mastodon.API.Account.mute(
                    session: session,
                    domain: authenticationBox.domain,
                    accountID: muteContext.targetUserID,
                    authorization: authenticationBox.userAuthorization
                ).singleOutput()

                result = .success(response)
            }
        } catch {
            result = .failure(error)
        }

        let response = try result.get()
        return response
    }

}

