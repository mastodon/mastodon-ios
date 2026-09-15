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
        public let useStandardWebPush: Bool?
        public let alerts: Alerts
        public let serverKey: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case endpoint
            case useStandardWebPush = "standard"
            case serverKey = "server_key"
            case alerts
        }
        
        public struct Alerts: Codable, Equatable {
            public let mention: Bool?
            public let status: Bool?
            public let reblog: Bool?
            public let follow: Bool?
            public let followRequest: Bool?
            public let favourite: Bool?
            public let poll: Bool?
            public let update: Bool?
            public let adminSignUp: Bool?
            public let adminReport: Bool?
            public let quote: Bool?
            public let quotedUpdate: Bool?
            
            enum CodingKeys: String, CodingKey {
                case mention
                case status
                case reblog
                case follow
                case followRequest = "follow_request"
                case favourite
                case poll
                case update
                case adminSignUp = "admin.sign_up"
                case adminReport = "admin.report"
                case quote
                case quotedUpdate = "quoted_update"
            }
            
            public init(
                mention: Bool?,
                status: Bool?,
                reblog: Bool?,
                follow: Bool?,
                followRequest: Bool?,
                favourite: Bool?,
                poll: Bool?,
                update: Bool?,
                adminSignUp: Bool?,
                adminReport: Bool?,
                quote: Bool?,
                quotedUpdate: Bool?
            ) {
                self.mention = mention
                self.status = status
                self.reblog = reblog
                self.follow = follow
                self.followRequest = followRequest
                self.favourite = favourite
                self.poll = poll
                self.update = update
                self.adminSignUp = adminSignUp
                self.adminReport = adminReport
                self.quote = quote
                self.quotedUpdate = quotedUpdate
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
            useStandardWebPush = try container.decodeIfPresent(Bool.self, forKey: .useStandardWebPush)
            alerts = try container.decode(Alerts.self, forKey: .alerts)
            serverKey = try container.decode(String.self, forKey: .serverKey)
        }
    }
    
    public struct EmptySubscription: Codable, Sendable {
        
    }
}
