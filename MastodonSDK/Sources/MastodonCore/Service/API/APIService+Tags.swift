//
//  APIService+Tags.swift
//  
//
//  Created by Marcus Kida on 23.11.22.
//

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
        
        return response
    }
    
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
        
        return response
    }
    
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

        return response
    }
}
