//
//  Mastodon+API+Suggestions.swift
//  
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation

extension Mastodon.API.Suggestions {
    static func suggestionsURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("suggestions")
    }

    /// Follow suggestions
    ///
    /// Server-generated suggestions on who to follow, based on previous positive interactions.
    ///
    /// Version history:
    /// 2.4.3 - added
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/suggestions/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: query
    ///   - authorization: User token.
    /// - Returns: `AnyPublisher` contains `Accounts` nested in the response
    public static func accounts(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Suggestions.Query?,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let request = Mastodon.API.get(
            url: suggestionsURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Account].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Mastodon.API.Suggestions {
    public struct Query: Codable, GetQuery {
        public init(limit: Int?) {
            self.limit = limit
        }

        public let limit: Int? // Maximum number of results to return. Defaults to 40.

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
