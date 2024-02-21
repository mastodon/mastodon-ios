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
    public struct Relationship: Codable, Sendable, Equatable, Hashable {
        /// The account ID
        public let id: String
        /// Are you following this user?
        public let following: Bool
        /// Do you have a pending follow request for this user?
        public let requested: Bool
        /// Are you featuring this user on your profile?
        public let endorsed: Bool
        /// Are you followed by this user?
        public let followedBy: Bool
        /// Are you muting this user?
        public let muting: Bool
        /// Are you muting notifications from this user?
        public let mutingNotifications: Bool
        /// Are you receiving this user’s boosts in your home timeline?
        public let showingReblogs: Bool
        /// Have you enabled notifications for this user?
        public let notifying: Bool
        /// Are you blocking this user?
        public let blocking: Bool
        /// Are you blocking this user’s domain?
        public let domainBlocking: Bool
        /// Is this user blocking you?
        public let blockedBy: Bool
        /// This user’s profile bio
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
