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
        
        #warning("TODO: Remove this with IOS-181, IOS-182")
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
           let me = authenticationBox.authentication.user(in: managedObjectContext)

            if let poll = response.value.poll {
                _ = Persistence.Poll.createOrMerge(
                    in: managedObjectContext,
                    context: .init(domain: domain, entity: poll, me: me, networkDate: response.networkDate)
                )
           }
        }

        return response
    }
    
    public func deleteStatus(
        status: MastodonStatus,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Status> {
        let authorization = authenticationBox.userAuthorization
        
        let managedObjectContext = backgroundManagedObjectContext
        let _query: Mastodon.API.Statuses.DeleteStatusQuery? = try? await managedObjectContext.perform {
            let _status = status.entity
            let status = _status.reblog ?? _status
            return Mastodon.API.Statuses.DeleteStatusQuery(id: status.id)
        }
        guard let query = _query else {
            throw APIError.implicit(.badRequest)
        }
        
        let response = try await Mastodon.API.Statuses.deleteStatus(
            session: session,
            domain: authenticationBox.domain,
            query: query,
            authorization: authorization
        ).singleOutput()

        return response
    }
    
}
