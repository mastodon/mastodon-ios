//
//  Mastodon+API+Search.swift
//
//
//  Created by sxiaojian on 2021/3/31.
//

import Combine
import Foundation

extension Mastodon.API.Search {
    static func searchURL(domain: String) -> URL {
        Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("search")
    }

    /// Search results
    ///
    /// Search for content in accounts, statuses and hashtags.
    ///
    /// Version history:
    /// 2.4.1 - added, limit hardcoded to 5
    /// 2.8.0 - add type, limit, offset, min_id, max_id, account_id
    /// 3.0.0 - add exclude_unreviewed param
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/search/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: search query
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Accounts,Hashtags,Status` nested in the response
    public static func search(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Search.Query,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.SearchResult>, Error> {
        let request = Mastodon.API.get(
            url: searchURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.SearchResult.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

public extension Mastodon.API.Search {
    struct Query: Codable, GetQuery {
        public init(accountID: Mastodon.Entity.Account.ID?, maxID: Mastodon.Entity.Status.ID?, minID: Mastodon.Entity.Status.ID?, type: String?, excludeUnreviewed: Bool?, q: String, resolve: Bool?, limit: Int?, offset: Int?, following: Bool?) {
            self.accountID = accountID
            self.maxID = maxID
            self.minID = minID
            self.type = type
            self.excludeUnreviewed = excludeUnreviewed
            self.q = q
            self.resolve = resolve
            self.limit = limit
            self.offset = offset
            self.following = following
        }

        public let accountID: Mastodon.Entity.Account.ID?
        public let maxID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let type: String?
        public let excludeUnreviewed: Bool? // Filter out unreviewed tags? Defaults to false. Use true when trying to find trending tags.
        public let q: String
        public let resolve: Bool? // Attempt WebFinger lookup. Defaults to false.
        public let limit: Int? // Maximum number of results to load, per type. Defaults to 20. Max 40.
        public let offset: Int? // Offset in search results. Used for pagination. Defaults to 0.
        public let following: Bool? // Only include accounts that the user is following. Defaults to false.

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            accountID.flatMap { items.append(URLQueryItem(name: "account_id", value: $0)) }
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            type.flatMap { items.append(URLQueryItem(name: "type", value: $0)) }
            excludeUnreviewed.flatMap { items.append(URLQueryItem(name: "exclude_unreviewed", value: $0.queryItemValue)) }
            items.append(URLQueryItem(name: "q", value: q))
            resolve.flatMap { items.append(URLQueryItem(name: "resolve", value: $0.queryItemValue)) }

            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            offset.flatMap { items.append(URLQueryItem(name: "offset", value: String($0))) }
            following.flatMap { items.append(URLQueryItem(name: "following", value: $0.queryItemValue)) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}

public extension Mastodon.API.Search {
    enum Scope: String {
        case accounts
        case hashTags

        public var rawValue: String {
            switch self {
            case .accounts:
                return "accounts"
            case .hashTags:
                return "hashtags"
            }
        }
    }
}
