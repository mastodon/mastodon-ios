//
//  Mastodon+Entity+FeaturedTag.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// FeaturedTag
    ///
    /// - Since: 3.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/featuredtag/)
    public struct FeaturedTag: Codable {
        public typealias ID = String
        
        public let id: ID
        public let name: String
        public let url: String?
        public let statusesCount: Int
        public let lastStatusAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case url
            case statusesCount = "statuses_count"
            case lastStatusAt = "last_status_at"
        }
    }
}
