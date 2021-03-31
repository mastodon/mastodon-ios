//
//  Mastodon+API+Trends.swift
//
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation

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
///   - authorization: User token.
/// - Returns: `AnyPublisher` contains `Hashtags` nested in the response

extension Mastodon.API.Trends {
    static func trendsURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("api/v1/trends")
    }

    public static func get(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Trends.Query?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> {
        let request = Mastodon.API.get(
            url: trendsURL(domain: domain),
            query: query,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Tag].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Mastodon.API.Trends {
    public struct Query: Codable, GetQuery {
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
