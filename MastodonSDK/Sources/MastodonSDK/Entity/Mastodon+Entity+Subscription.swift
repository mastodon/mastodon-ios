//
//  Mastodon+Entity+Subscription.swift
//  
//
//  Created by ihugo on 2021/4/9.
//

import Foundation


extension Mastodon.Entity {
    /// Subscription
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/4/26
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/pushsubscription/)
    public struct Subscription: Codable {
        // Base
        public let id: String
        public let endpoint: String
        public let alerts: Alerts
        public let serverKey: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case endpoint
            case serverKey = "server_key"
            case alerts
        }
        
        public struct Alerts: Codable {
            public let follow: Bool?
            public let followRequest: Bool?
            public let favourite: Bool?
            public let reblog: Bool?
            public let mention: Bool?
            public let poll: Bool?
            
            enum CodingKeys: String, CodingKey {
                case follow
                case followRequest = "follow_request"
                case favourite
                case reblog
                case mention
                case poll
            }
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            var id = try? container.decode(String.self, forKey: .id)
            if nil == id, let numId = try? container.decode(Int.self, forKey: .id) {
                id = String(numId)
            }
            self.id = id ?? ""
            
            endpoint = try container.decode(String.self, forKey: .endpoint)
            alerts = try container.decode(Alerts.self, forKey: .alerts)
            serverKey = try container.decode(String.self, forKey: .serverKey)
        }
    }
    
    public struct EmptySubscription: Codable, Sendable {
        
    }
}
