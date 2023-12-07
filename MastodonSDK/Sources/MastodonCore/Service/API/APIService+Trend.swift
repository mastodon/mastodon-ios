//
//  APIService+Trend.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import Foundation
import MastodonSDK
import CoreDataStack

extension APIService {
    
    public func trendHashtags(
        domain: String,
        query: Mastodon.API.Trends.HashtagQuery?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Tag]> {
        let response = try await Mastodon.API.Trends.hashtags(
            session: session,
            domain: domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
    public func trendStatuses(
        domain: String,
        query: Mastodon.API.Trends.StatusQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let response = try await Mastodon.API.Trends.statuses(
            session: session,
            domain: domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }
    
    public func trendLinks(
        domain: String,
        query: Mastodon.API.Trends.LinkQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Link]> {
        let response = try await Mastodon.API.Trends.links(
            session: session,
            domain: domain,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }
    
}
