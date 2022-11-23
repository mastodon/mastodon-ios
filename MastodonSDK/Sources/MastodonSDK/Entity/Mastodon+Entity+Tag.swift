//
//  Mastodon+Entity+Tag.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Tag
    ///
    /// - Since: 0.9.0
    /// - Version: 4.0.0
    /// # Last Update
    ///   2022/11/22
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/tag/)
    public struct Tag: Hashable, Codable {
        
        // Base
        public let name: String
        public let url: String
        
        public let history: [History]?
        public let following: Bool?
        
        enum CodingKeys: String, CodingKey {
            case name
            case url
            case history
            case following
        }
        
        public static func == (lhs: Mastodon.Entity.Tag, rhs: Mastodon.Entity.Tag) -> Bool {
            return lhs.name == rhs.name
                && lhs.url == rhs.url
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(url)
        }
        
        public func copy(following: Bool?) -> Self {
            Tag(name: name, url: url, history: history, following: following)
        }
    }
}
