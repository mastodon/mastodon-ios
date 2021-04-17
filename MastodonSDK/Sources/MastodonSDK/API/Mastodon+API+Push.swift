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
    ///   2021/4/9
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
    ///   2021/4/9
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
    ///   2021/4/9
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
}

extension Mastodon.API.Subscriptions {
    public struct CreateSubscriptionQuery: Codable, PostQuery {
        let endpoint: String
        let p256dh: String
        let auth: String
        let favourite: Bool?
        let follow: Bool?
        let reblog: Bool?
        let mention: Bool?
        let poll: Bool?
        
        var queryItems: [URLQueryItem]? {
            var items = [URLQueryItem]()
            
            items.append(URLQueryItem(name: "subscription[endpoint]", value: endpoint))
            items.append(URLQueryItem(name: "subscription[keys][p256dh]", value: p256dh))
            items.append(URLQueryItem(name: "subscription[keys][auth]", value: auth))
            
            if let followValue = follow?.queryItemValue {
                let followItem = URLQueryItem(name: "data[alerts][follow]", value: followValue)
                items.append(followItem)
            }
            
            if let favouriteValue = favourite?.queryItemValue {
                let favouriteItem = URLQueryItem(name: "data[alerts][favourite]", value: favouriteValue)
                items.append(favouriteItem)
            }
            
            if let reblogValue = reblog?.queryItemValue {
                let reblogItem = URLQueryItem(name: "data[alerts][reblog]", value: reblogValue)
                items.append(reblogItem)
            }
            
            if let mentionValue = mention?.queryItemValue {
                let mentionItem = URLQueryItem(name: "data[alerts][mention]", value: mentionValue)
                items.append(mentionItem)
            }
            return items
        }
        
        public init(
            endpoint: String,
            p256dh: String,
            auth: String,
            favourite: Bool?,
            follow: Bool?,
            reblog: Bool?,
            mention: Bool?,
            poll: Bool?
        ) {
            self.endpoint = endpoint
            self.p256dh = p256dh
            self.auth = auth
            self.favourite = favourite
            self.follow = follow
            self.reblog = reblog
            self.mention = mention
            self.poll = poll
        }
    }
    
    public struct UpdateSubscriptionQuery: Codable, PutQuery {
        let favourite: Bool?
        let follow: Bool?
        let reblog: Bool?
        let mention: Bool?
        let poll: Bool?
        
        var queryItems: [URLQueryItem]? {
            var items = [URLQueryItem]()
            
            if let followValue = follow?.queryItemValue {
                let followItem = URLQueryItem(name: "data[alerts][follow]", value: followValue)
                items.append(followItem)
            }
            
            if let favouriteValue = favourite?.queryItemValue {
                let favouriteItem = URLQueryItem(name: "data[alerts][favourite]", value: favouriteValue)
                items.append(favouriteItem)
            }
            
            if let reblogValue = reblog?.queryItemValue {
                let reblogItem = URLQueryItem(name: "data[alerts][reblog]", value: reblogValue)
                items.append(reblogItem)
            }
            
            if let mentionValue = mention?.queryItemValue {
                let mentionItem = URLQueryItem(name: "data[alerts][mention]", value: mentionValue)
                items.append(mentionItem)
            }
            return items
        }
        
        public init(
            favourite: Bool?,
            follow: Bool?,
            reblog: Bool?,
            mention: Bool?,
            poll: Bool?
        ) {
            self.favourite = favourite
            self.follow = follow
            self.reblog = reblog
            self.mention = mention
            self.poll = poll
        }
    }
}
