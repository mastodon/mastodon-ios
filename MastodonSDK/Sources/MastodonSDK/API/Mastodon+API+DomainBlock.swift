//
//  File.swift
//
//
//  Created by sxiaojian on 2021/4/29.
//

import Foundation
import Combine

extension Mastodon.API.DomainBlock {
    static func domainBlockEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("domain_blocks")
    }

    /// Fetch domain blocks
    ///
    /// - Since: 1.4.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/domain_blocks/)
    /// - Parameters:
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `String` nested in the response
    public static func getDomainblocks(
        domain: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization,
        query: Mastodon.API.DomainBlock.Query
    ) -> AnyPublisher<Mastodon.Response.Content<[String]>, Error> {
        let url = domainBlockEndpointURL(domain: domain)
        let request = Mastodon.API.get(url: url, query: query, authorization: authorization)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [String].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    /// Block a domain
    ///
    /// - Since: 1.4.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/domain_blocks/)
    /// - Parameters:
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `String` nested in the response
    public static func blockDomain(
        domain: String,
        blockDomain:String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error> {
        let query = Mastodon.API.DomainBlock.BlockQuery(domain: blockDomain)
        let request = Mastodon.API.post(
            url: domainBlockEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Empty.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Unblock a domain
    ///
    /// - Since: 1.4.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/domain_blocks/)
    /// - Parameters:
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `String` nested in the response
    public static func unblockDomain(
        domain: String,
        blockDomain:String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Empty>, Error> {
        let query = Mastodon.API.DomainBlock.BlockDeleteQuery(domain: blockDomain)
        let request = Mastodon.API.delete(
            url: domainBlockEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Empty.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Mastodon.API.DomainBlock {
    public struct Query: GetQuery {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let limit: Int?

        public init(
            maxID: Mastodon.Entity.Status.ID?,
            sinceID: Mastodon.Entity.Status.ID?,
            limit: Int?
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.limit = limit
        }

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
    public struct BlockDeleteQuery: Codable, DeleteQuery {
        
        public let domain: String
        
        public init(domain: String) {
            self.domain = domain
        }
    }
    
    public struct BlockQuery: Codable, PostQuery {
        
        public let domain: String
        
        public init(domain: String) {
            self.domain = domain
        }
    }
}
