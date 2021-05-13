//
//  File.swift
//  
//
//  Created by ihugo on 2021/4/9.
//

import Foundation
import Combine

extension Mastodon.API.Subscriptions {
    
    static func pushEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("push/subscription")
    }
 
    /// Get current subscription
    ///
    /// Using this endpoint to get current subscription
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/25
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Subscription` nested in the response
    public static func subscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error>  {
        let request = Mastodon.API.get(
            url: pushEndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Subscription.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Subscribe to push notifications
    ///
    /// Add a Web Push API subscription to receive notifications. Each access token can have one push subscription. If you create a new subscription, the old subscription is deleted.
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/25
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Subscription` nested in the response
    public static func createSubscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization,
        query: CreateSubscriptionQuery
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error>  {
        let request = Mastodon.API.post(
            url: pushEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Subscription.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Change types of notifications
    ///
    /// Updates the current push subscription. Only the data part can be updated. To change fundamentals, a new subscription must be created instead.
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/25
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Subscription` nested in the response
    public static func updateSubscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization,
        query: UpdateSubscriptionQuery
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error>  {
        let request = Mastodon.API.put(
            url: pushEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Subscription.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Remove current subscription
    ///
    /// Removes the current Web Push API subscription.
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/26
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/notifications/push/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token. Could be nil if status is public
    /// - Returns: `AnyPublisher` contains `Subscription` nested in the response
    public static func removeSubscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.EmptySubscription>, Error> {
        let request = Mastodon.API.delete(
            url: pushEndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.EmptySubscription.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Mastodon.API.Subscriptions {
    
    public typealias Policy = QueryData.Policy
    
    public struct QuerySubscription: Codable {
        let endpoint: String
        let keys: Keys
        
        public init(
            endpoint: String,
            keys: Keys
        ) {
            self.endpoint = endpoint
            self.keys = keys
        }
        
        public struct Keys: Codable {
            let p256dh: String
            let auth: String
            
            public init(p256dh: Data, auth: Data) {
                self.p256dh = p256dh.base64UrlEncodedString()
                self.auth = auth.base64UrlEncodedString()
            }
        }
    }
    
    public struct QueryData: Codable {
        let policy: Policy?
        let alerts: Alerts
        
        public init(
            policy: Policy?,
            alerts: Mastodon.API.Subscriptions.QueryData.Alerts
        ) {
            self.policy = policy
            self.alerts = alerts
        }
        
        public struct Alerts: Codable {
            let favourite: Bool?
            let follow: Bool?
            let reblog: Bool?
            let mention: Bool?
            let poll: Bool?

            public init(favourite: Bool?, follow: Bool?, reblog: Bool?, mention: Bool?, poll: Bool?) {
                self.favourite = favourite
                self.follow = follow
                self.reblog = reblog
                self.mention = mention
                self.poll = poll
            }
        }
        
        public enum Policy: RawRepresentable, Codable {
            case all
            case followed
            case follower
            case none
            
            case _other(String)
            
            public init?(rawValue: String) {
                switch rawValue {
                case "all":             self = .all
                case "followed":        self = .followed
                case "follower":        self = .follower
                case "none":            self = .none

                default:                self = ._other(rawValue)
                }
            }
            
            public var rawValue: String {
                switch self {
                case .all:                      return "all"
                case .followed:                 return "followed"
                case .follower:                 return "follower"
                case .none:                     return "none"
                case ._other(let value):        return value
                }
            }
        }
    }
    
    
    public struct CreateSubscriptionQuery: Codable, PostQuery {
        let subscription: QuerySubscription
        let data: QueryData

        public init(
            subscription: Mastodon.API.Subscriptions.QuerySubscription,
            data: Mastodon.API.Subscriptions.QueryData
        ) {
            self.subscription = subscription
            self.data = data
        }
    }
    
    public struct UpdateSubscriptionQuery: Codable, PutQuery {
        
        let data: QueryData
                
        public init(data: Mastodon.API.Subscriptions.QueryData) {
            self.data = data
        }
        
        var queryItems: [URLQueryItem]? { nil }
    }
}
