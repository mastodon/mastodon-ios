//
//  Mastodon+Entity+Conversation.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Conversation
    ///
    /// - Since: 2.6.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/conversation/)
    public struct Conversation: Codable {
        public typealias ID = String
        
        public let id: ID
        public let accounts: [Account]
        public let unread: Bool
        
        public let lastStatus: Status?
        
        enum CodingKeys: String, CodingKey {
            case id
            case accounts
            case unread
            
            case lastStatus = "last_status"
        }
    }
}
