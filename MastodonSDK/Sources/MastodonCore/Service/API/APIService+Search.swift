//
//  APIService+Search.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import Combine
import MastodonSDK

extension APIService {
 
    public func search(
        query: Mastodon.API.V2.Search.Query,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.SearchResult> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization

        let response = try await Mastodon.API.V2.Search.search(
            session: session,
            domain: domain,
            query: query,
            authorization: authorization
        ).singleOutput()
        
        return response
    }

}
