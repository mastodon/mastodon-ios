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
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let request = Mastodon.API.get(
            url: familiarFollowersEndpointURL(domain: domain),
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
    
    public struct FamiliarFollowersQuery: GetQuery {
        public let accounts: [Mastodon.Entity.Account.ID]
        
        public init(accounts: [Mastodon.Entity.Account.ID]) {
            self.accounts = accounts
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            let accountsValue = accounts.joined(separator: ",")
            if !accountsValue.isEmpty {
                items.append(URLQueryItem(name: "accounts", value: accountsValue))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
