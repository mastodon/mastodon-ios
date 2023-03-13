//
//  Mastodon+Entity+Announcement.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Announcement
    ///
    /// - Since: 3.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/announcement/)
    public struct Announcement: Codable, Sendable {
        
        public typealias ID = String
        
        // Base
        public let id: ID
        public let text: String
        public let published: Bool?
        public let allDay: Bool
        public let createdAt: Date
        public let updatedAt: Date
        public let read: Bool
        public let reactions: [AnnouncementReaction]
        
        public let scheduledAt: Date?
        public let startsAt: Date?
        public let endsAt: Date?
        
        enum CodingKeys: String, CodingKey {
            case id
            case text
            case published
            case allDay
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case read
            case reactions
            
            case scheduledAt = "scheduled_at"
            case startsAt = "starts_at"
            case endsAt
        }
    }
}
