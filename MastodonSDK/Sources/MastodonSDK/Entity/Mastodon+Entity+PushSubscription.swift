//
//  Mastodon+Entity+PushSubscription.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import Foundation

extension Mastodon.Entity {
    /// PushSubscription
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/pushsubscription/)
    public struct PushSubscription: Codable {
        public typealias ID = String
        
        public let id: ID
        public let endpoint: String
        public let serverKey: String
        public let alerts: Alerts
        
        enum CodingKeys: String, CodingKey {
            case id
            case endpoint
            case serverKey = "server_key"
            case alerts
        }
    }
}

extension Mastodon.Entity.PushSubscription {
    public struct Alerts: Codable {
        public let follow: Bool
        public let favourite: Bool
        public let reblog: Bool
        public let mention: Bool
        public let poll: Bool?
    }
}
