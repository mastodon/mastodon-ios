//
//  Mastodon+Entity+Source.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Source
    ///
    /// - Since: 1.5.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/3
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/source/)
    public struct Source: Codable, Sendable {
        
        // Base
        public let note: String
        public let fields: [Field]?
        
        public let privacy: Privacy?
        public let sensitive: Bool?
        public let language: String?        // (ISO 639-1 language two-letter code)
        public let followRequestsCount: Int?
        
        enum CodingKeys: String, CodingKey {
            case note
            case fields
            
            case privacy
            case sensitive
            case language
            case followRequestsCount = "follow_requests_count"
        }
    }
}

extension Mastodon.Entity.Source {
    public typealias Privacy = Mastodon.Entity.Status.Visibility
}
