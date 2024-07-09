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

    public struct UpdateNotificationPolicyQuery: Codable, PatchQuery {
        public let filterNotFollowing: Bool
        public let filterNotFollowers: Bool
        public let filterNewAccounts: Bool
        public let filterPrivateMentions: Bool

        enum CodingKeys: String, CodingKey {
            case filterNotFollowing = "filter_not_following"
            case filterNotFollowers = "filter_not_followers"
            case filterNewAccounts = "filter_new_accounts"
            case filterPrivateMentions = "filter_private_mentions"
        }

        public init(filterNotFollowing: Bool, filterNotFollowers: Bool, filterNewAccounts: Bool, filterPrivateMentions: Bool) {
            self.filterNotFollowing = filterNotFollowing
            self.filterNotFollowers = filterNotFollowers
            self.filterNewAccounts = filterNewAccounts
            self.filterPrivateMentions = filterPrivateMentions
        }
    }

    public static func getNotificationPolicy(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.NotificationPolicy> {
        let request = Mastodon.API.get(
            url: notificationPolicyEndpointURL(domain: domain),
            authorization: authorization
        )

        let (data, response) = try await session.data(for: request)

        let value = try Mastodon.API.decode(type: Mastodon.Entity.NotificationPolicy.self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }

    public static func updateNotificationPolicy(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization,
        query: Mastodon.API.Notifications.UpdateNotificationPolicyQuery
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.NotificationPolicy> {
        let request = Mastodon.API.patch(
            url: notificationPolicyEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(type: Mastodon.Entity.NotificationPolicy.self, from: data, response: response)

        return Mastodon.Response.Content(value: value, response: response)
    }
}

extension Mastodon.API.Notifications {
    internal static func notificationRequestsEndpointURL(domain: String) -> URL {
        notificationsEndpointURL(domain: domain).appendingPathComponent("requests")
    }

    public static func getNotificationRequests(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.NotificationRequest]> {
        let request = Mastodon.API.get(
            url: notificationRequestsEndpointURL(domain: domain),
            authorization: authorization
        )

        let (data, response) = try await session.data(for: request)

        let value = try Mastodon.API.decode(type: [Mastodon.Entity.NotificationRequest].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}
