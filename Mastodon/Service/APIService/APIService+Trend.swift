//
//  APIService+Trend.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import Foundation
import MastodonSDK

extension APIService {
    func trends(
        domain: String,
        query: Mastodon.API.Trends.Query?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Tag]> {
        let response = try await Mastodon.API.Trends.get(
            session: session,
            domain: domain,
            query: query
        ).singleOutput()
        
        return response
    }
}
