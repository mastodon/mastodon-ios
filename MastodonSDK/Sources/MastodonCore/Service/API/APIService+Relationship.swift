//
//  APIService+Relationship.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import UIKit
import Combine
import MastodonSDK

extension APIService {
 
    public func relationship(
        records: [Mastodon.Entity.Account],
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {
        let managedObjectContext = backgroundManagedObjectContext

        let _query: Mastodon.API.Account.RelationshipQuery? = try? await managedObjectContext.perform {
            var ids: [Mastodon.Entity.Account.ID] = []
            for record in records {
                guard record.id != authenticationBox.userID else { continue }
                ids.append(record.id)
            }
            guard !ids.isEmpty else { return nil }
            return Mastodon.API.Account.RelationshipQuery(ids: ids)
        }
        guard let query = _query else {
            throw APIError.implicit(.badRequest)
        }

        let response = try await Mastodon.API.Account.relationships(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }


    public func relationship(
        forAccounts accounts: [Mastodon.Entity.Account],
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {

        let ids: [Mastodon.Entity.Account.ID] = accounts.compactMap { $0.id }

        guard ids.isEmpty == false else { throw APIError.implicit(.badRequest) }

        let query = Mastodon.API.Account.RelationshipQuery(ids: ids)

        let response = try await Mastodon.API.Account.relationships(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }

}
