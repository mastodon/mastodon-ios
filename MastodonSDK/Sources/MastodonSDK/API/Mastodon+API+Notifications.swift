//
//  File.swift
//  
//
//  Created by BradGao on 2021/4/1.
//

import Foundation
import Combine

extension Mastodon.API.Notifications {
    static func notificationsEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent("notifications")
    }
    static func getNotificationEndpointURL(domain: String, notificationID: String) -> URL {
        notificationsEndpointURL(domain: domain).appendingPathComponent(notificationID)
    }
    
    /// Get all notifications
    ///
    /// - Since: 0.0.0
    /// - Version: 3.1.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `GetAllNotificationsQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func getAll(
        session: URLSession,
        domain: String,
        query: GetAllNotificationsQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Notification]>, Error>  {
        let request = Mastodon.API.get(
            url: notificationsEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Notification].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Get a single notification
    ///
    /// - Since: 0.0.0
    /// - Version: 3.1.0
    /// # Last Update
    ///   2021/4/1
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - notificationID: ID of the notification.
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func get(
        session: URLSession,
        domain: String,
        notificationID: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Notification>, Error>  {
        let request = Mastodon.API.get(
            url: getNotificationEndpointURL(domain: domain, notificationID: notificationID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Notification.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct GetAllNotificationsQuery: Codable, PagedQueryType, GetQuery {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        public let excludeTypes: [String]?
        public let accountID: String?
    
        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil,
            excludeTypes: [String]? = nil,
            accountID: String? = nil
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
            self.excludeTypes = excludeTypes
            self.accountID = accountID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            if let excludeTypes = excludeTypes {
                excludeTypes.forEach {
                    items.append(URLQueryItem(name: "exclude_types[]", value: $0))
                }
            }
            accountID.flatMap { items.append(URLQueryItem(name: "account_id", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}
