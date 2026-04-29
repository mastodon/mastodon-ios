//
//  File.swift
//
//
//  Created by BradGao on 2021/4/1.
//

import Combine
import Foundation

extension Mastodon.API.Notifications {
    internal static func notificationsEndpointURL(
        domain: String, grouped: Bool = false
    ) -> URL {
        if grouped {
            Mastodon.API.endpointV2URL(domain: domain).appendingPathComponent(
                "notifications")
        } else {
            Mastodon.API.endpointURL(domain: domain).appendingPathComponent(
                "notifications")
        }
    }

    internal static func getNotificationEndpointURL(
        domain: String, notificationID: String
    ) -> URL {
        notificationsEndpointURL(domain: domain).appendingPathComponent(
            notificationID)
    }

    /// Get all grouped notifications
    ///
    /// - Since: 4.3.0
    /// - Version: 4.3.0
    /// # Last Update
    ///   2025/01/8
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/grouped_notifications/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `GroupedNotificationsQuery` with query parameters
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func getGroupedNotifications(
        session: URLSession,
        domain: String,
        query: Mastodon.API.Notifications.GroupedQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.GroupedNotificationsResults> {
        let request = Mastodon.API.get(
            url: notificationsEndpointURL(domain: domain, grouped: true),
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.GroupedNotificationsResults.self, from: data,
            response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
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
    ) -> AnyPublisher<
        Mastodon.Response.Content<[Mastodon.Entity.Notification]>, Error
    > {
        let request = Mastodon.API.get(
            url: notificationsEndpointURL(domain: domain, grouped: false),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(
                    type: [Mastodon.Entity.Notification].self, from: data,
                    response: response)
                return Mastodon.Response.Content(
                    value: value, response: response)
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
    ) -> AnyPublisher<
        Mastodon.Response.Content<Mastodon.Entity.Notification>, Error
    > {
        let request = Mastodon.API.get(
            url: getNotificationEndpointURL(
                domain: domain, notificationID: notificationID),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(
                    type: Mastodon.Entity.Notification.self, from: data,
                    response: response)
                return Mastodon.Response.Content(
                    value: value, response: response)
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
        public let types: [Mastodon.Entity.NotificationType]?
        public let excludeTypes: [Mastodon.Entity.NotificationType]?
        public let supportedTypes: [Mastodon.Entity.NotificationType]? // providing a list of supported types means we will receive new notification types with a fallback attribute to display until we fully implement them
        public let accountID: String?

        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil,
            types: [Mastodon.Entity.NotificationType]? = nil,
            excludeTypes: [Mastodon.Entity.NotificationType]? = nil,
            supportedTypes: [Mastodon.Entity.NotificationType]?,
            accountID: String? = nil
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
            self.types = types
            self.excludeTypes = excludeTypes
            self.supportedTypes = supportedTypes
            self.accountID = accountID
        }

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap {
                items.append(URLQueryItem(name: "max_id", value: $0))
            }
            sinceID.flatMap {
                items.append(URLQueryItem(name: "since_id", value: $0))
            }
            minID.flatMap {
                items.append(URLQueryItem(name: "min_id", value: $0))
            }
            limit.flatMap {
                items.append(URLQueryItem(name: "limit", value: String($0)))
            }
            if let types = types {
                types.forEach {
                    items.append(
                        URLQueryItem(name: "types[]", value: $0.rawValue))
                }
            }
            if let excludeTypes = excludeTypes {
                excludeTypes.forEach {
                    items.append(
                        URLQueryItem(
                            name: "exclude_types[]", value: $0.rawValue))
                }
            }
            if let supportedTypes {
                supportedTypes.forEach {
                    items.append(
                        URLQueryItem(
                            name: "supported_types[]", value: $0.rawValue))
                }
            }
            accountID.flatMap {
                items.append(URLQueryItem(name: "account_id", value: $0))
            }
            guard !items.isEmpty else { return nil }
            return items
        }
    }

    /// Note that providing `types` will end up ignoring `supportedTypes`. That is, no unknown notifications with `fallback` will be returned.  To receive unknown notifications with `fallback`, use `excludeTypes` to filter out any you know you don't want, and provide your list of `supportedTypes` to receive `fallback` for any you do not declare as supported.
    public struct GroupedQuery: PagedQueryType, GetQuery {
        public let maxID: Mastodon.Entity.Status.ID?
        public let sinceID: Mastodon.Entity.Status.ID?
        public let minID: Mastodon.Entity.Status.ID?
        public let limit: Int?
        public let types: [Mastodon.Entity.NotificationType]?
        public let excludeTypes: [Mastodon.Entity.NotificationType]?
        public let supportedTypes: [Mastodon.Entity.NotificationType]? // providing a list of supported types means we will receive new notification types with a fallback attribute to display until we fully implement them
        public let accountID: String?
        public let groupedTypes: [String]?
        public let expandAccounts: Bool

        public init(
            maxID: Mastodon.Entity.Status.ID? = nil,
            sinceID: Mastodon.Entity.Status.ID? = nil,
            minID: Mastodon.Entity.Status.ID? = nil,
            limit: Int? = nil,
            types: [Mastodon.Entity.NotificationType]? = nil,
            excludeTypes: [Mastodon.Entity.NotificationType]? = nil,
            supportedTypes: [Mastodon.Entity.NotificationType]?,
            accountID: String? = nil,
            groupedTypes: [String]? = ["favourite", "follow", "reblog"],
            expandAccounts: Bool = false
        ) {
            self.maxID = maxID
            self.sinceID = sinceID
            self.minID = minID
            self.limit = limit
            self.types = types
            self.excludeTypes = excludeTypes
            self.supportedTypes = supportedTypes
            self.accountID = accountID
            self.groupedTypes = groupedTypes
            self.expandAccounts = expandAccounts
        }

        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            maxID.flatMap {
                items.append(URLQueryItem(name: "max_id", value: $0))
            }
            sinceID.flatMap {
                items.append(URLQueryItem(name: "since_id", value: $0))
            }
            minID.flatMap {
                items.append(URLQueryItem(name: "min_id", value: $0))
            }
            limit.flatMap {
                items.append(URLQueryItem(name: "limit", value: String($0)))
            }
            if let types = types {
                types.forEach {
                    items.append(
                        URLQueryItem(name: "types[]", value: $0.rawValue))
                }
            }
            if let excludeTypes = excludeTypes {
                excludeTypes.forEach {
                    items.append(
                        URLQueryItem(
                            name: "exclude_types[]", value: $0.rawValue))
                }
            }
            if let supportedTypes {
                supportedTypes.forEach {
                    items.append(
                        URLQueryItem(
                            name: "supported_types[]", value: $0.rawValue))
                }
            }
            accountID.flatMap {
                items.append(URLQueryItem(name: "account_id", value: $0))
            }
            // TODO: implement groupedTypes
            //            if let groupedTypes {
            //                items.append(URLQueryItem(name: "grouped_types", value: groupedTypes))
            //            }
            items.append(
                URLQueryItem(
                    name: "expand_accounts",
                    value: expandAccounts ? "full" : "partial_avatars"))
            guard !items.isEmpty else { return nil }
            return items
        }
    }
}

//MARK: - Notification Policy

extension Mastodon.API.Notifications {
    internal static func notificationPolicyEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointV2URL(domain: domain)
            .appendingPathComponent("notifications").appendingPathComponent(
                "policy")
    }

    public struct UpdateNotificationPolicyQuery: Codable, PatchQuery {
        public let forNotFollowing:
            Mastodon.Entity.NotificationPolicy.NotificationFilterAction
        public let forNotFollowers:
            Mastodon.Entity.NotificationPolicy.NotificationFilterAction
        public let forNewAccounts:
            Mastodon.Entity.NotificationPolicy.NotificationFilterAction
        public let forPrivateMentions:
            Mastodon.Entity.NotificationPolicy.NotificationFilterAction
        public let forLimitedAccounts:
            Mastodon.Entity.NotificationPolicy.NotificationFilterAction

        enum CodingKeys: String, CodingKey {
            case forNotFollowing = "for_not_following"
            case forNotFollowers = "for_not_followers"
            case forNewAccounts = "for_new_accounts"
            case forPrivateMentions = "for_private_mentions"
            case forLimitedAccounts = "for_Limited_accounts"
        }

        public init(
            forNotFollowing: Mastodon.Entity.NotificationPolicy
                .NotificationFilterAction,
            forNotFollowers: Mastodon.Entity.NotificationPolicy
                .NotificationFilterAction,
            forNewAccounts: Mastodon.Entity.NotificationPolicy
                .NotificationFilterAction,
            forPrivateMentions: Mastodon.Entity.NotificationPolicy
                .NotificationFilterAction,
            forLimitedAccounts: Mastodon.Entity.NotificationPolicy
                .NotificationFilterAction
        ) {
            self.forNotFollowing = forNotFollowing
            self.forNotFollowers = forNotFollowers
            self.forNewAccounts = forNewAccounts
            self.forPrivateMentions = forPrivateMentions
            self.forLimitedAccounts = forLimitedAccounts
        }
    }

    public static func getNotificationPolicy(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws
        -> Mastodon.Response.Content<Mastodon.Entity.NotificationPolicy>
    {
        let request = Mastodon.API.get(
            url: notificationPolicyEndpointURL(domain: domain),
            authorization: authorization
        )

        let (data, response) = try await session.data(for: request)

        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.NotificationPolicy.self, from: data,
            response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }

    public static func updateNotificationPolicy(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization,
        query: Mastodon.API.Notifications.UpdateNotificationPolicyQuery
    ) async throws
        -> Mastodon.Response.Content<Mastodon.Entity.NotificationPolicy>
    {
        let request = Mastodon.API.patch(
            url: notificationPolicyEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.NotificationPolicy.self, from: data,
            response: response)

        return Mastodon.Response.Content(value: value, response: response)
    }
}

extension Mastodon.API.Notifications {
    internal static func notificationRequestsEndpointURL(domain: String) -> URL
    {
        notificationsEndpointURL(domain: domain).appendingPathComponent(
            "requests")
    }

    internal static func notificationRequestEndpointURL(
        domain: String, id: String
    ) -> URL {
        notificationRequestsEndpointURL(domain: domain).appendingPathComponent(
            id)
    }

    internal static func acceptNotificationRequestEndpointURL(
        domain: String, id: String
    ) -> URL {
        notificationRequestEndpointURL(domain: domain, id: id)
            .appendingPathComponent("accept")
    }

    internal static func dismissNotificationRequestEndpointURL(
        domain: String, id: String
    ) -> URL {
        notificationRequestEndpointURL(domain: domain, id: id)
            .appendingPathComponent("dismiss")
    }

    public static func getNotificationRequests(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws
        -> Mastodon.Response.Content<[Mastodon.Entity.NotificationRequest]>
    {
        let request = Mastodon.API.get(
            url: notificationRequestsEndpointURL(domain: domain),
            authorization: authorization
        )

        let (data, response) = try await session.data(for: request)

        let value = try Mastodon.API.decode(
            type: [Mastodon.Entity.NotificationRequest].self, from: data,
            response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }

    public static func acceptNotificationRequest(
        id: String,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[String: String]> {
        let request = Mastodon.API.post(
            url: acceptNotificationRequestEndpointURL(domain: domain, id: id),
            authorization: authorization
        )

        let (data, response) = try await session.data(for: request)

        // we expect an empty dictionary
        let value = try Mastodon.API.decode(
            type: [String: String].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }

    public static func dismissNotificationRequest(
        id: String,
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<[String: String]> {
        let request = Mastodon.API.post(
            url: dismissNotificationRequestEndpointURL(domain: domain, id: id),
            authorization: authorization
        )

        let (data, response) = try await session.data(for: request)

        // we expect an empty dictionary
        let value = try Mastodon.API.decode(
            type: [String: String].self, from: data, response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
}
