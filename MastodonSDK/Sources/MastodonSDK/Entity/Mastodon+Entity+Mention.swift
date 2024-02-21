//
//  Mastodon+Entity+Mention.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Mention
    ///
    /// - Since: 0.6.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/Status/#Mention)
    public struct Mention: Codable, Sendable {
        
        public typealias ID = String
        
        public let id: ID
        public let username: String
        public let acct: String
        public let url: String
        
        
        enum CodingKeys: String, CodingKey {
            case id
            case username
            case acct
            case url
        }
        
    }
}
