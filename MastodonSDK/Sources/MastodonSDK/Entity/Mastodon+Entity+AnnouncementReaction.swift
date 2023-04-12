//
//  Mastodon+Entity+AnnouncementReaction.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// AnnouncementReaction
    ///
    /// - Since: 3.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/announcementreaction/)
    public struct AnnouncementReaction: Codable, Sendable {
        // Base
        public let name: String
        public let count: Int
        public let me: Bool

        // Custom Emoji
        public let url: String?
        public let staticURL: String?
        
        enum CodingKeys: String, CodingKey {
            case name
            case count
            case me
            case url
            case staticURL = "static_url"
        }
    }
}
