//
//  Mastodon+API+Trends.swift
//
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation

extension Mastodon.API.Trends {
    
    static func trendsURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("trends")
    }

    /// Trending tags
    ///
    /// Tags that are being used more frequently within the past week.
    ///
    /// Version history:
    /// 3.0.0 - added
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/trends/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: query
    /// - Returns: `AnyPublisher` contains `Hashtags` nested in the response
    
    public static func hashtags(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Trends.HashtagQuery?,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> {
        let request = Mastodon.API.get(
            url: trendsURL(domain: domain),
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

    public struct HashtagQuery: Codable, GetQuery {
        public init(limit: Int?) {
            self.limit = limit
        }

        public let limit: Int? // Maximum number of results to return. Defaults to 10.

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}

extension Mastodon.API.Trends {
    
    static func trendStatusesURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("trends")
            .appendingPathComponent("statuses")
    }

    /// Trending status
    ///
    /// TBD
    ///
    /// Version history:
    /// 3.?.?
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/trends/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: query
    /// - Returns: `[Status]` nested in the response
    
    public static func statuses(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Trends.StatusQuery?,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error> {
        let request = Mastodon.API.get(
            url: trendStatusesURL(domain: domain),
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

    public struct StatusQuery: Codable, GetQuery {

        public let offset: Int?
        public let limit: Int? // Maximum number of results to return. Defaults to 10.
        
        public init(
            offset: Int?,
            limit: Int?
        ) {
            self.offset = offset
            self.limit = limit
        }

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            offset.flatMap { items.append(URLQueryItem(name: "offset", value: String($0))) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}

extension Mastodon.API.Trends {
    
    static func trendLinksURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("trends")
            .appendingPathComponent("links")
    }

    /// Trending links
    ///
    /// TBD
    ///
    /// Version history:
    /// 3.?.?
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/trends/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: query
    /// - Returns: `[Link]` nested in the response
    
    public static func links(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Trends.LinkQuery?,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Link]>, Error> {
        let request = Mastodon.API.get(
            url: trendLinksURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Link].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public typealias LinkQuery = StatusQuery
    
}
