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
import CommonOSLog
import MastodonSDK

extension APIService {
 
    public func relationship(
        records: [ManagedObjectRecord<MastodonUser>],
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Relationship]> {
        let managedObjectContext = backgroundManagedObjectContext
        
        let _query: Mastodon.API.Account.RelationshipQuery? = try? await managedObjectContext.perform {
            var ids: [MastodonUser.ID] = []
            for record in records {
                guard let user = record.object(in: managedObjectContext) else { continue }
                guard user.id != authenticationBox.userID else { continue }
                ids.append(user.id)
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
        
        try await managedObjectContext.performChanges {
            guard let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user else {
                // assertionFailure()
                return
            }

            let relationships = response.value
            for record in records {
                guard let user = record.object(in: managedObjectContext) else { continue }
                guard let relationship = relationships.first(where: { $0.id == user.id }) else { continue }
                
                Persistence.MastodonUser.update(
                    mastodonUser: user,
                    context: Persistence.MastodonUser.RelationshipContext(
                        entity: relationship,
                        me: me,
                        networkDate: response.networkDate
                    )
                )
            }   // end for in
        }

        return response
    }
    
}
