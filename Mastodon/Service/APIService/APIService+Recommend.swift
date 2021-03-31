//
//  APIService+Recommend.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
import MastodonSDK
import Combine

extension APIService {
 
    func recommendAccount(
        domain: String,
        query: Mastodon.API.Suggestions.Query,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization

        return Mastodon.API.Suggestions.get(session: session, domain: domain, query: query, authorization: authorization)
    }
    
    func recommendTrends(
        domain: String,
        query: Mastodon.API.Trends.Query
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> {
        return Mastodon.API.Trends.get(session: session, domain: domain, query: query)
    }
}
