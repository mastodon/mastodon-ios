//
//  Mastodon+Entity+Marker.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Marker
    ///
    /// - Since: 3.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/marker/)
    public struct Marker: Codable {
        // Base
        public let home: Position
        public let notifications: Position
    }
}

extension Mastodon.Entity.Marker {
    public struct Position: Codable {
        public let lastReadID: Mastodon.Entity.Status.ID
        public let updatedAt: Date
        public let version: Int
        
        enum CodingKeys: String, CodingKey {
            case lastReadID = "last_read_id"
            case updatedAt = "updated_at"
            case version
        }
    }
}
