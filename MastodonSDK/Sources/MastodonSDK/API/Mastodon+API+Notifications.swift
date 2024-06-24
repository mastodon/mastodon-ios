//
//  File.swift
//
//
//  Created by BradGao on 2021/4/1.
//

import Combine
import Foundation

extension Mastodon.API.Notifications {
    internal static func notificationsEndpointURL(domain: String) -> URL {
        Mastodon.API.endpointURL(domain: domain).appendingPathComponent("notifications")
    }

    internal static func getNotificationEndpointURL(domain: String, notificationID: String) -> URL {
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
    ///   - query: `NotificationsQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func getNotifications(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Notifications.Query,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Notification]>, Error> {
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
    public static func getNotification(
        session: URLSession,
        domain: String,
        notificationID: Mastodon.Entity.Notification.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Notification>, Error> {
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
}

extension Mastodon.API.Notifications {
    public struct Query: PagedQueryType, GetQuery {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        public let types: [Mastodon.Entity.Notification.NotificationType]?
        public let excludeTypes: [Mastodon.Entity.Notification.NotificationType]?
        public let accountID: String?
    
        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil,
            types: [Mastodon.Entity.Notification.NotificationType]? = nil,
            excludeTypes: [Mastodon.Entity.Notification.NotificationType]? = nil,
            accountID: String? = nil
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
            self.types = types
            self.excludeTypes = excludeTypes
            self.accountID = accountID
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap { items.append(URLQueryItem(name: "max_id", value: $0)) }
            sinceID.flatMap { items.append(URLQueryItem(name: "since_id", value: $0)) }
            minID.flatMap { items.append(URLQueryItem(name: "min_id", value: $0)) }
            limit.flatMap { items.append(URLQueryItem(name: "limit", value: String($0))) }
            if let types = types {
                types.forEach {
                    items.append(URLQueryItem(name: "types[]", value: $0.rawValue))
                }
            }
            if let excludeTypes = excludeTypes {
                excludeTypes.forEach {
                    items.append(URLQueryItem(name: "exclude_types[]", value: $0.rawValue))
                }
            }
            accountID.flatMap { items.append(URLQueryItem(name: "account_id", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}

//MARK: - Notification Policy

extension Mastodon.API.Notifications {
    internal static func notificationPolicyEndpointURL(domain: String) -> URL {
        notificationsEndpointURL(domain: domain).appendingPathComponent("policy")
    }

    public static func getNotificationPolicy(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.NotificationPolicy>, Error> {
        let request = Mastodon.API.get(
            url: notificationPolicyEndpointURL(domain: domain),
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.NotificationPolicy.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
