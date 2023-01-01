//
//  APIService+Thread.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    public func statusContext(
        statusID: Mastodon.Entity.Status.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Context> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Statuses.statusContext(
            session: session,
            domain: domain,
            statusID: statusID,
            authorization: authorization
        ).singleOutput()
        
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user
            let value = response.value.ancestors + response.value.descendants
            
            for entity in value {
                _ = Persistence.Status.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Status.PersistContext(
                        domain: domain,
                        entity: entity,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
            }
        }
        
        return response
    }   // end func
    
    public func fetchThread(
        statusID: Mastodon.Entity.Status.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Status? {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        let managedObjectContext = self.backgroundManagedObjectContext

        let responseOne = try await Mastodon.API.Statuses.status(
            session: session,
            domain: domain,
            statusID: statusID,
            authorization: authorization
        ).singleOutput()

        try await managedObjectContext.performChanges {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user
            _ = Persistence.Status.createOrMerge(
                in: managedObjectContext,
                context: Persistence.Status.PersistContext(
                    domain: domain,
                    entity: responseOne.value,
                    me: me,
                    statusCache: nil,
                    userCache: nil,
                    networkDate: responseOne.networkDate
                )
            )
        }
        
        let responseTwo = try await Mastodon.API.Statuses.statusContext(
            session: session,
            domain: domain,
            statusID: statusID,
            authorization: authorization
        ).singleOutput()
        
        try await managedObjectContext.performChanges {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user
            let value = responseTwo.value.ancestors + responseTwo.value.descendants
            
            for entity in value {
                _ = Persistence.Status.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Status.PersistContext(
                        domain: domain,
                        entity: entity,
                        me: me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: responseTwo.networkDate
                    )
                )
            }
        }
                
        var result: Status?
        try await managedObjectContext.perform {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user

            if let status = Persistence.Status.fetch(in: managedObjectContext,
                                     context: Persistence.Status.PersistContext(
                                        domain: domain,
                                        entity: responseOne.value,
                                        me: me,
                                        statusCache: nil,
                                        userCache: nil,
                                        networkDate: responseOne.networkDate
                                     )) {
                result = status
            }
        }
        
        return result
    }
}
