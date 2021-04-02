//
//  Mastodon+API+Account+Friendship.swift
//  
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import Foundation
import Combine

extension Mastodon.API.Account {
    
    static func accountsRelationshipsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/relationships")
    }

    /// Check relationships to other accounts
    ///
    /// Find out whether a given account is followed, blocked, muted, etc.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/#perform-actions-on-an-account/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `RelationshipQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Relationship]` nested in the response
    public static func relationships(
        session: URLSession,
        domain: String,
        query: RelationshipQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Relationship]>, Error> {
        let request = Mastodon.API.get(
            url: accountsRelationshipsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Relationship].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct RelationshipQuery: GetQuery {
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
