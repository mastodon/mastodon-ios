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
    static func homeTimelineEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("timelines/home")
    }
    static func hashtagTimelineEndpointURL(domain: String, hashtag: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("timelines/tag/\(hashtag)")
    }
    static func listTimelineEndpointURL(domain: String, id: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("timelines/list/\(id)")
    }
    
    /// View public timeline statuses
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/19
    /// # Reference
    ///   [Document](https://https://docs.joinmastodon.org/methods/timelines/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `PublicTimelineQuery` with query parameters
    ///   - authorization:  required if the instance has disabled public preview
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func `public`(
        session: URLSession,
        domain: String,
        query: PublicTimelineQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error>  {
        let request = Mastodon.API.get(
            url: publicTimelineEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// View statuses from followed users.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/3
    /// # Reference
    ///   [Document](https://https://docs.joinmastodon.org/methods/timelines/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `PublicTimelineQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func home(
        session: URLSession,
        domain: String,
        query: HomeTimelineQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error>  {
        let request = Mastodon.API.get(
            url: homeTimelineEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// View public statuses containing the given hashtag.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/29
    /// # Reference
    ///   [Document](https://https://docs.joinmastodon.org/methods/timelines/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `HashtagTimelineQuery` with query parameters
    ///   - hashtag: Content of a #hashtag, not including # symbol.
    ///   - authorization: User token, auth is required if public preview is disabled
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func hashtag(
        session: URLSession,
        domain: String,
        query: HashtagTimelineQuery,
        hashtag: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let request = Mastodon.API.get(
            url: hashtagTimelineEndpointURL(domain: domain, hashtag: hashtag),
            query: query,
            authorization: authorization
        )
        
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public static func list(
        session: URLSession,
        domain: String,
        query: PublicTimelineQuery,
        id: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Status]> {
        let request = Mastodon.API.get(
            url: listTimelineEndpointURL(domain: domain, id: id),
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request)
        
        let value = try Mastodon.API.decode(type: [Mastodon.Entity.Status].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}

public protocol PagedQueryType {
    var maxID: Mastodon.Entity.Status.ID? { get }
    var sinceID: Mastodon.Entity.Status.ID? { get }
}

extension Mastodon.API.Timeline {
    
    public typealias TimelineQuery = PagedQueryType
    
    public struct PublicTimelineQuery: Codable, TimelineQuery, GetQuery {
        
        public let local: Bool?
        public let remote: Bool?
        public let onlyMedia: Bool?
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
    
        public init(
            local: Bool? = nil,
            remote: Bool? = nil,
            onlyMedia: Bool? = nil,
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
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
    
    public struct HomeTimelineQuery: Codable, TimelineQuery, GetQuery {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        public let local: Bool?
    
        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil,
            local: Bool? = nil
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
            self.local = local
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            local.flatMap { items.append(URLQueryItem(name: "local", value: $0.queryItemValue)) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
    public struct HashtagTimelineQuery: Codable, TimelineQuery, GetQuery {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        public let local: Bool?
        public let onlyMedia: Bool?
    
        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil,
            local: Bool? = nil,
            onlyMedia: Bool? = nil
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
            self.local = local
            self.onlyMedia = onlyMedia
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            local.flatMap { items.append(URLQueryItem(name: "local", value: $0.queryItemValue)) }
            onlyMedia.flatMap { items.append(URLQueryItem(name: "only_media", value: $0.queryItemValue)) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}
