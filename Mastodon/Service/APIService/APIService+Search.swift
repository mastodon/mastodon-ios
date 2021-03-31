//
//  APIService+Search.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import MastodonSDK
import Combine

extension APIService {
 
    func search(
        domain: String,
        query: Mastodon.API.Search.Query,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Search.search(session: session, domain: domain, query: query, authorization: authorization)
    }
}
