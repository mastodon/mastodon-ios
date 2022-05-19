//
//  Mastodon+API+Account+FamiliarFollowers.swift
//  
//
//  Created by MainasuK on 2022-5-13.
//

import Foundation
import Combine

// https://github.com/mastodon/mastodon/pull/17700
extension Mastodon.API.Account {
    
    private static func familiarFollowersEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("accounts")
            .appendingPathComponent("familiar_followers")
    }
    
    /// Fetch familiar followers
    ///
    /// - Since: 3.5.?
    /// - Version: 3.5.2
    /// # Last Update
    ///   2022/5/13
    /// # Reference
    ///   [Document](none)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `FamiliarFollowersQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Mastodon.Entity.Account]` nested in the response
    public static func familiarFollowers(
        session: URLSession,
        domain: String,
        query: FamiliarFollowersQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.FamiliarFollowers]>, Error> {
        let request = Mastodon.API.get(
            url: familiarFollowersEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.FamiliarFollowers].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct FamiliarFollowersQuery: GetQuery {
        public let ids: [Mastodon.Entity.Account.ID]
        
        public init(ids: [Mastodon.Entity.Account.ID]) {
            self.ids = ids
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            for id in ids {
                items.append(URLQueryItem(name: "id[]", value: id))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
