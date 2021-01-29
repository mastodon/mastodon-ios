//
//  Mastodon+Entity+Account.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Entity {
    
    // FIXME: prefer `Account`. `User` will be deprecated
    public typealias User = Account
    
    /// Account
    ///
    /// - Since: 0.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/account/)
    public class Account: Codable {
        
        public typealias ID = String

        // Base
        public let id: ID
        public let username: String
        public let acct: String
        public let url: String
        
        // Display
        public let displayName: String
        public let note: String
        public let avatar: String
        public let avatarStatic: String
        public let header: String
        public let headerStatic: String
        public let locked: Bool
        public let emojis: [Emoji]?
        public let discoverable: Bool?
        
        // Statistical
        public let createdAt: Date
        public let lastStatusAt: Date?
        public let statusesCount: Int
        public let followersCount: Int
        public let followingCount: Int
        
        public let moved: User?
        public let fields: [Field]?
        public let bot: Bool?
        public let source: Source?
        public let suspended: Bool?
        public let muteExpiresAt: Date?
        
        enum CodingKeys: String, CodingKey {
            case id
            case username
            case acct
            case url
            
            case displayName = "display_name"
            case note
            case avatar
            case avatarStatic = "avatar_static"
            case header
            case headerStatic = "header_static"
            case locked
            case emojis
            case discoverable
            
            case createdAt = "created_at"
            case lastStatusAt = "last_status_at"
            case statusesCount = "statuses_count"
            case followersCount = "followers_count"
            case followingCount = "following_count"
            case moved
            
            case fields
            case bot
            case source
            case suspended
            case muteExpiresAt = "mute_expires_at"
        }
    }
    
}
