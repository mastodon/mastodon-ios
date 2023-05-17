//
//  Mastodon+API+Statuses+FavoriteBy.swift
//  
//
//  Created by MainasuK on 2022-5-17.
//

import Foundation
import Combine

extension Mastodon.API.Statuses {
    
    private static func favoriteByEndpointURL(domain: String, statusID: Mastodon.Entity.Status.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("statuses")
            .appendingPathComponent(statusID)
            .appendingPathComponent("favourited_by")        // use same word from api
    }
    
    /// Favourited by
    ///
    /// View who favourited a given status.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.5.2
    /// # Last Update
    ///   2022/5/17
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/statuses/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - statusID: id for status
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Status` nested in the response
    public static func favoriteBy(
        session: URLSession,
        domain: String,
        statusID: Mastodon.Entity.Status.ID,
        query: FavoriteByQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error>  {
        let request = Mastodon.API.get(
            url: favoriteByEndpointURL(domain: domain, statusID: statusID),
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
    
    public struct FavoriteByQuery: Codable, GetQuery {
                
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
