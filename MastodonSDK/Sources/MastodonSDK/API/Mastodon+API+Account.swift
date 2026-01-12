//
//  Mastodon+API+Account.swift
//  
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine

// MARK: - Retrieve information
extension Mastodon.API.Account {

    static func accountsInfoEndpointURL(domain: String, id: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("accounts")
            .appendingPathComponent(id)
    }

    /// Retrieve information
    ///
    /// View information about a profile.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccountInfoQuery` with account query information,
    ///   - authorization: user token
    /// - Returns: `AnyPublisher` contains `Account` nested in the response
    public static func accountInfo(
        session: URLSession,
        domain: String,
        userID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let request = Mastodon.API.get(
            url: accountsInfoEndpointURL(domain: domain, id: userID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Account.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Retrieve information
    ///
    /// Get information about multiple profiles.
    ///
    /// - Since: 4.3.0
    /// - Version: 4.3.0
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `MultipleAccountsQuery` with array of account ids,
    ///   - authorization: user token
    /// - Returns: `AnyPublisher` contains array of `Account` nested in the response
    public static func accountsInfo(
        session: URLSession,
        domain: String,
        userIDs: [Mastodon.Entity.Account.ID],
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Account]>, Error> {
        let request = Mastodon.API.get(
            url: Mastodon.API.endpointURL(domain: domain)
                .appendingPathComponent("accounts"),
            query: MultipleAccountsQuery(ids: userIDs),
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Array<Mastodon.Entity.Account>.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct MultipleAccountsQuery: GetQuery {
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

extension Mastodon.API.Account {
    
    static func accountStatusesEndpointURL(domain: String, accountID: Mastodon.Entity.Account.ID) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/\(accountID)/statuses")
    }
    
    /// View statuses from followed users.
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/30
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccountStatusesQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func statuses(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        query: AccountStatusesQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Status]>, Error>  {
        let request = Mastodon.API.get(
            url: accountStatusesEndpointURL(domain: domain, accountID: accountID),
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
    
    public struct AccountStatusesQuery: GetQuery {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let excludeReplies: Bool?    // undocumented
        public let excludeReblogs: Bool?
        public let onlyMedia: Bool?
        public let tagged: String?
        public let pinned: Bool?
        public let limit: Int?
        
        public init(
            maxID: Mastodon.Entity.Status.ID?,
            sinceID: Mastodon.Entity.Status.ID?,
            excludeReplies: Bool?,
            excludeReblogs: Bool?,
            onlyMedia: Bool?,
            tagged: String?,
            pinned: Bool?,
            limit: Int?
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.excludeReplies = excludeReplies
            self.excludeReblogs = excludeReblogs
            self.onlyMedia = onlyMedia
            self.tagged = tagged
            self.pinned = pinned
            self.limit = limit
        }

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            excludeReplies.flatMap { items.append(URLQueryItem(name: "exclude_replies", value: $0.queryItemValue)) }
            excludeReblogs.flatMap { items.append(URLQueryItem(name: "exclude_reblogs", value: $0.queryItemValue)) }
            onlyMedia.flatMap { items.append(URLQueryItem(name: "only_media", value: $0.queryItemValue)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            tagged.flatMap { items.append(URLQueryItem(name: "tagged", value: $0)) }
            pinned.flatMap { items.append(URLQueryItem(name: "pinned", value: $0.queryItemValue)) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
    
}

extension Mastodon.API.Account {
    static func accountsLookupEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/lookup")
    }

    public struct AccountLookupQuery: GetQuery {

        public var acct: String
        
        public init(acct: String) {
            self.acct = acct
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            items.append(URLQueryItem(name: "acct", value: acct))
            return items
        }
    }
    
    /// lookup account by acct.
    ///
    /// - Version: 3.3.1

    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccountInfoQuery` with account query information,
    ///   - authorization: app token
    /// - Returns: `AnyPublisher` contains `Account` nested in the response
    public static func lookupAccount(
        session: URLSession,
        domain: String,
        query: AccountLookupQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let request = Mastodon.API.get(
            url: accountsLookupEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Account.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
