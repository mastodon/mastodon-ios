//
//  Mastodon+Entity+ScheduledStatus.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import Foundation

extension Mastodon.Entity {
    /// ScheduledStatus
    ///
    /// - Since: 2.7.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/scheduledstatus/)
    public struct ScheduledStatus: Codable {
        public typealias ID = String
        
        public let id: ID
        public let scheduledAt: Date
        public let params: Parameters
        public let mediaAttachments: [Attachment]
    }
}

extension Mastodon.Entity.ScheduledStatus {
    public struct Parameters: Codable {
        public let text: String
        public let inReplyToID: Mastodon.Entity.Account.ID?
        public let mediaIDs: [Mastodon.Entity.Attachment.ID]?
        public let sensitive: Bool?
        public let spoilerText: String?
        public let visibility: Visibility
        public let scheduledAt: Date?
        public let poll: Mastodon.Entity.Poll?         // undocumented
        public let applicationID: String
        
        // public let idempotency: Bool?               // undoumented
        // public let withRateLimit                    // undoumented
        
        enum CodingKeys: String, CodingKey {
            case text
            case inReplyToID = "in_reply_to_id"
            case mediaIDs = "media_ids"
            case sensitive
            case spoilerText = "spoiler_text"
            case visibility
            case scheduledAt = "scheduled_at"
            case poll
            case applicationID = "application_id"
        }
    }
}

extension Mastodon.Entity.ScheduledStatus.Parameters {
    public typealias Visibility = Mastodon.Entity.Source.Privacy
}
