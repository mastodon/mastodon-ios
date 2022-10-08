//
//  APIService+Poll.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-3.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import CommonOSLog
import MastodonSDK

extension APIService {
    
    public func poll(
        poll: ManagedObjectRecord<Poll>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {
        let authorization = authenticationBox.userAuthorization
        
        let managedObjectContext = self.backgroundManagedObjectContext
        let pollID: Poll.ID = try await managedObjectContext.perform {
            guard let poll = poll.object(in: managedObjectContext) else {
                throw APIError.implicit(.badRequest)
            }
            return poll.id
        }
        
        let response = try await Mastodon.API.Polls.poll(
            session: session,
            domain: authenticationBox.domain,
            pollID: pollID,
            authorization: authorization
        ).singleOutput()
        
        try await managedObjectContext.performChanges {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user
            _ = Persistence.Poll.createOrMerge(
                in: managedObjectContext,
                context: Persistence.Poll.PersistContext(
                    domain: authenticationBox.domain,
                    entity: response.value,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }
    
}

extension APIService {

    public func vote(
        poll: ManagedObjectRecord<Poll>,
        choices: [Int],
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Poll> {
        let managedObjectContext = backgroundManagedObjectContext
        let _pollID: Poll.ID? = try await managedObjectContext.perform {
            guard let poll = poll.object(in: managedObjectContext) else { return nil }
            return poll.id
        }
        
        guard let pollID = _pollID else {
            throw APIError.implicit(.badRequest)
        }

        let response = try await Mastodon.API.Polls.vote(
            session: session,
            domain: authenticationBox.domain,
            pollID: pollID,
            query: Mastodon.API.Polls.VoteQuery(choices: choices),
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        try await managedObjectContext.performChanges {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user
            _ = Persistence.Poll.createOrMerge(
                in: managedObjectContext,
                context: Persistence.Poll.PersistContext(
                    domain: authenticationBox.domain,
                    entity: response.value,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }
    
}
