//
//  File.swift
//  
//
//  Created by ihugo on 2021/4/9.
//

import Foundation
import Combine

extension Mastodon.API.Notification {
    
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
    /// - Returns: `AnyPublisher` contains `Poll` nested in the response
    public static func subscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization?
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
    
    /// Change types of notifications
    ///
    /// Using this endpoint to change types of notifications
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
    /// - Returns: `AnyPublisher` contains `Poll` nested in the response
    public static func createSubscription(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization?,
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
}

extension Mastodon.API.Notification {
    public struct CreateSubscriptionQuery: PostQuery {
        var queryItems: [URLQueryItem]?
        var contentType: String?
        var body: Data?
        
        let follow: Bool?
        let favourite: Bool?
        let reblog: Bool?
        let mention: Bool?
        let poll: Bool?
        
        // iTODO: missing parameters
        // subscription[endpoint]
        // subscription[keys][p256dh]
        // subscription[keys][auth]
        public init(favourite: Bool?,
                    follow: Bool?,
                    reblog: Bool?,
                    mention: Bool?,
                    poll: Bool?) {
            self.follow = follow
            self.favourite = favourite
            self.reblog = reblog
            self.mention = mention
            self.poll = poll
            
            queryItems = [URLQueryItem]()
            
            if let followValue = follow?.queryItemValue {
                let followItem = URLQueryItem(name: "data[alerts][follow]", value: followValue)
                queryItems?.append(followItem)
            }
            
            if let favouriteValue = favourite?.queryItemValue {
                let favouriteItem = URLQueryItem(name: "data[alerts][favourite]", value: favouriteValue)
                queryItems?.append(favouriteItem)
            }
            
            if let reblogValue = reblog?.queryItemValue {
                let reblogItem = URLQueryItem(name: "data[alerts][reblog]", value: reblogValue)
                queryItems?.append(reblogItem)
            }
            
            if let mentionValue = mention?.queryItemValue {
                let mentionItem = URLQueryItem(name: "data[alerts][mention]", value: mentionValue)
                queryItems?.append(mentionItem)
            }
        }
    }
}
