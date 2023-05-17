//
//  Mastodon+Entity+Link.swift
//  
//
//  Created by MainasuK on 2022-4-13.
//

import Foundation

extension Mastodon.Entity {
    /// History
    ///
    /// - Since: 3.5.0
    /// - Version: 3.5.1
    /// # Last Update
    ///   2022/4/13
    /// # Reference
    ///  [Document](TBD)
    public struct Link: Codable, Sendable {
        public let url: String
        public let title: String
        public let description: String
        public let providerName: String
        public let providerURL: String
        public let image: String
        public let width: Int
        public let height: Int
        public let blurhash: String
        public let history: [History]
        
        enum CodingKeys: String, CodingKey {
            case url
            case title
            case description
            case providerName = "provider_name"
            case providerURL = "provider_url"
            case image
            case width
            case height
            case blurhash
            case history
        }
    }
}

extension Mastodon.Entity.Link: Hashable {
    public static func == (lhs: Mastodon.Entity.Link, rhs: Mastodon.Entity.Link) -> Bool {
        return lhs.url == rhs.url
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
