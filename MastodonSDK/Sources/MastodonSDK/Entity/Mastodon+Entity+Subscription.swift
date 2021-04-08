//
//  File.swift
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
    ///   2021/4/9
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
            public let follow: Bool
            public let favourite: Bool
            public let reblog: Bool
            public let mention: Bool
            public let poll: Bool
        }
    }
}
