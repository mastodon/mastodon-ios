//
//  APIService+PublicTimeline.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-29.
//

import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
 
    public func publicTimeline(
        query: Mastodon.API.Timeline.PublicTimelineQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Timeline.public(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        #warning("TODO: Remove this with IOS-181, IOS-182")
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
           let me = authenticationBox.authentication.user(in: managedObjectContext)

           for entity in response.value {
               guard let poll = entity.poll else { continue }
               _ = Persistence.Poll.createOrMerge(
                in: managedObjectContext,
                context: .init(domain: domain, entity: poll, me: me, networkDate: response.networkDate)
               )
           }
        }

        return response
    }   // end func
    
}
