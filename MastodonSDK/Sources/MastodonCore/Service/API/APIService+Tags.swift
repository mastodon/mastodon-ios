//
//  APIService+Tags.swift
//  
//
//  Created by Marcus Kida on 23.11.22.
//

import os.log
import Foundation
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    public func getTagInformation(
        for tag: String,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Tag> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Tags.getTagInformation(
            session: session,
            domain: domain,
            tagId: tag,
            authorization: authorization
        ).singleOutput()
        
        return try await persistTag(from: response, domain: domain, authenticationBox: authenticationBox)
    }   // end func
    
    public func followTag(
        for tag: String,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Tag> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Tags.followTag(
            session: session,
            domain: domain,
            tagId: tag,
            authorization: authorization
        ).singleOutput()
        
        return try await persistTag(from: response, domain: domain, authenticationBox: authenticationBox)
    }   // end func
    
    public func unfollowTag(
        for tag: String,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Tag> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let response = try await Mastodon.API.Tags.unfollowTag(
            session: session,
            domain: domain,
            tagId: tag,
            authorization: authorization
        ).singleOutput()

        return try await persistTag(from: response, domain: domain, authenticationBox: authenticationBox)
    }   // end func
}

fileprivate extension APIService {
    func persistTag(
        from response: Mastodon.Response.Content<Mastodon.Entity.Tag>,
        domain: String,
        authenticationBox: MastodonAuthenticationBox
    ) async throws ->  Mastodon.Response.Content<Mastodon.Entity.Tag> {
        let managedObjectContext = self.backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            let me = authenticationBox.authenticationRecord.object(in: managedObjectContext)?.user

            _ = Persistence.Tag.createOrMerge(
                in: managedObjectContext,
                context: Persistence.Tag.PersistContext(
                    domain: domain,
                    entity: response.value,
                    me: me,
                    networkDate: response.networkDate
                )
            )
        }
        
        return response
    }
}
