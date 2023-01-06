//
//  Mastodon+API+Account+FollowedTags.swift
//  
//
//  Created by Marcus Kida on 22.11.22.
//

import Foundation
import Combine

extension Mastodon.API.Account {

    static func followedTagsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("followed_tags")
    }
    
    /// Followed Tags
    ///
    /// View your followed hashtags.
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.3
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/followed_tags/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Tag]` nested in the response
    public static func followedTags(
        session: URLSession,
        domain: String,
        query: FollowedTagsQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> {
        let request = Mastodon.API.get(
            url: followedTagsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Tag].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct FollowedTagsQuery: Codable, GetQuery {
                
        public let limit: Int? // default 100
        
        enum CodingKeys: String, CodingKey {
            case limit
        }
        
        public init(
            limit: Int?
        ) {
            self.limit = limit
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }

    }
    
}
