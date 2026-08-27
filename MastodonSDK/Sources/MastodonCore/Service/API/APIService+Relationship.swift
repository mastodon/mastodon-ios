//
//  APIService+Relationship.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import UIKit
import Combine
import MastodonSDK

extension Notification.Name {
    public static let relationshipChanged = Notification.Name(rawValue: "org.joinmastodon.app.relationship-changed")
}

public enum UserInfoKey {
    public static let relationship = "relationship"
}

extension APIService {
    public func relationship(
        forAccounts accounts: [Mastodon.Entity.Account],
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> [String : Mastodon.Entity.Relationship] {
        
        let ids: [String] = accounts.compactMap { $0.id }
        return try await relationship(forAccountIds: ids, authenticationBox: authenticationBox)
    }
    
    public func relationship(
        forAccountIds ids: [String],
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> [String : Mastodon.Entity.Relationship] {

        guard ids.isEmpty == false else { throw APIError.implicit(.badRequest) }

        let dedupedIds = Array(Set(ids))
        let chunkSize = 100
        var relationships = [String : Mastodon.Entity.Relationship]()
        for start in stride(from: 0, to: dedupedIds.count, by: chunkSize) { // asking for too many at once can cause an API error
            let end = min(start + chunkSize, dedupedIds.count)
            let chunk = Array(dedupedIds[start..<end])
            let query = Mastodon.API.Account.RelationshipQuery(ids: chunk)
            let response = try await Mastodon.API.Account.relationships(
                session: session,
                domain: authenticationBox.domain,
                query: query,
                authorization: authenticationBox.userAuthorization
            ).singleOutput()

            for relationship in response.value {
                relationships[relationship.id] = relationship
            }
        }
        return relationships
    }

}
