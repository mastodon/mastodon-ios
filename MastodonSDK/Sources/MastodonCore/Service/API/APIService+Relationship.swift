//
//  APIService+Relationship.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
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
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {

        let ids: [String] = accounts.compactMap { $0.id }

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
