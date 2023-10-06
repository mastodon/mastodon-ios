//
//  APIService+Status.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {

    public func status(
        statusID: Mastodon.Entity.Status.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Statuses.status(
            session: session,
            domain: domain,
            statusID: statusID,
            authorization: authorization
        ).singleOutput()

        return response
    }
    
    public func deleteStatus(
        status: Mastodon.Entity.Status,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Statuses.deleteStatus(
            session: session,
            domain: authenticationBox.domain,
            query: Mastodon.API.Statuses.DeleteStatusQuery(id: status.id),
            authorization: authorization
        ).singleOutput()

        return response
    }
    
}
