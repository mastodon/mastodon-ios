//
//  Mastodon+Entity+Relationship.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import Foundation

extension Mastodon.Entity {
    /// Relationship
    ///
    /// - Since: 0.6.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/relationship/)
    public struct Relationship: Codable {
        public typealias ID = String
        
        public let id: ID
        public let following: Bool
        public let requested: Bool?
        public let endorsed: Bool?
        public let followedBy: Bool
        public let muting: Bool?
        public let mutingNotifications: Bool?
        public let showingReblogs: Bool?
        public let notifying: Bool?
        public let blocking: Bool
        public let domainBlocking: Bool?
        public let blockedBy: Bool?
        public let note: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case following
            case requested
            case endorsed
            case followedBy = "followed_by"
            case muting
            case mutingNotifications = "muting_notifications"
            case showingReblogs = "showing_reblogs"
            case notifying
            case blocking
            case domainBlocking = "domain_blocking"
            case blockedBy = "blocked_by"
            case note
            
        }
    }
}
