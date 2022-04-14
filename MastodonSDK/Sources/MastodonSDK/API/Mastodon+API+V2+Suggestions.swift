//
//  Mastodon+API+V2+Suggestions.swift
//  
//
//  Created by sxiaojian on 2021/4/20.
//

import Combine
import Foundation

extension Mastodon.API.V2.Suggestions {
    static func suggestionsURL(domain: String) -> URL {
        Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("suggestions")
    }

    /// Follow suggestions, No document for now
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: query
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `AccountsSuggestion` nested in the response
    public static func accounts(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Suggestions.Query?,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.V2.SuggestionAccount]>, Error> {
        let request = Mastodon.API.get(
            url: suggestionsURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.V2.SuggestionAccount].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
