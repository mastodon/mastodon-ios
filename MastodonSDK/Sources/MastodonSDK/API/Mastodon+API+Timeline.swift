//
//  Mastodon+API+Timeline.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation
import Combine

extension Mastodon.API.Timeline {
    
    static func publicTimelineEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("timelines/public")
    }
    
    public static func `public`(
        session: URLSession,
        domain: String,
        query: PublicTimelineQuery
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Toot]>, Error>  {
        let request = Mastodon.API.get(
            url: publicTimelineEndpointURL(domain: domain),
            query: query,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Toot].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Timeline {
    public struct PublicTimelineQuery: Codable, GetQuery {
        
        public let local: Bool?
        public let remote: Bool?
        public let onlyMedia: Bool?
        public let maxID: Mastodon.Entity.Toot.ID?
        public let sinceID: Mastodon.Entity.Toot.ID?
        public let minID: Mastodon.Entity.Toot.ID?
        public let limit: Int?
    
        public init(
            local: Bool? = nil,
            remote: Bool? = nil,
            onlyMedia: Bool? = nil,
            maxID: Mastodon.Entity.Toot.ID? = nil,
            sinceID: Mastodon.Entity.Toot.ID? = nil,
            minID: Mastodon.Entity.Toot.ID? = nil,
            limit: Int? = nil
        ) {
            self.local = local
            self.remote = remote
            self.onlyMedia = onlyMedia
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            local.flatMap { items.append(URLQueryItem(name: "local", value: $0.queryItemValue)) }
            remote.flatMap { items.append(URLQueryItem(name: "remote", value: $0.queryItemValue)) }
            onlyMedia.flatMap { items.append(URLQueryItem(name: "only_media", value: $0.queryItemValue)) }
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
