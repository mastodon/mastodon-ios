//
//  APIService+Trend.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import Foundation
import MastodonSDK

extension APIService {
    
    public func trendHashtags(
        domain: String,
        query: Mastodon.API.Trends.HashtagQuery?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Tag]> {
        let response = try await Mastodon.API.Trends.hashtags(
            session: session,
            domain: domain,
            query: query
        ).singleOutput()
        
        return response
    }
    
    public func trendStatuses(
        domain: String,
        query: Mastodon.API.Trends.StatusQuery
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let response = try await Mastodon.API.Trends.statuses(
            session: session,
            domain: domain,
            query: query
        ).singleOutput()
        
        let managedObjectContext = backgroundManagedObjectContext
        try await managedObjectContext.performChanges {
            for entity in response.value {
                _ = Persistence.Status.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Status.PersistContext(
                        domain: domain,
                        entity: entity,
                        me: nil,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: response.networkDate
                    )
                )
            }   // end for … in
        }
        
        return response
    }
    
    public func trendLinks(
        domain: String,
        query: Mastodon.API.Trends.LinkQuery
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Link]> {
        let response = try await Mastodon.API.Trends.links(
            session: session,
            domain: domain,
            query: query
        ).singleOutput()
        
        return response
    }
    
}
