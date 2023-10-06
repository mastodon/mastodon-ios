//
//  APIService+Status+Publish.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-20.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {

    public func publishStatus(
        domain: String,
        idempotencyKey: String?,
        query: Mastodon.API.Statuses.PublishStatusQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.Statuses.publishStatus(
            session: session,
            domain: domain,
            idempotencyKey: idempotencyKey,
            query: query,
            authorization: authorization
        ).singleOutput()

        return response
    }

}
