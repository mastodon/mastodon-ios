//
//  Mastodon+API+Account+Followers.swift
//  
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import Foundation
import Combine

extension Mastodon.API.Account {

    static func followersEndpointURL(domain: String, userID: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("accounts")
            .appendingPathComponent(userID)
            .appendingPathComponent("followers")
    }
    
    /// Followers
    ///
    /// Accounts which follow the given account, if network is not hidden by the account owner.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.4.1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - userID: ID of the account in the database
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Account]` nested in the response
    public static func followers(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        query: FollowerQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let request = Mastodon.API.get(
            url: followersEndpointURL(domain: domain, userID: userID),
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
    
    public struct FollowerQuery: Codable, GetQuery {
                
        public let maxID: String?
        public let limit: Int?      // default 40
        
        enum CodingKeys: String, CodingKey {
            case maxID = "max_id"
            case limit
        }
        
        public init(
            maxID: String?,
            limit: Int?
        ) {
            self.maxID = maxID
            self.limit = limit
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }

    }
    
}
