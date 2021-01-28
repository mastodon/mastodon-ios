//
//  Mastodon+Entity+Poll.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Poll
    ///
    /// - Since: 2.8.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/poll/)
    public struct Poll: Codable {
        public typealias ID = String
        
        public let id: ID
        public let expiresAt: Date
        public let expired: Bool
        public let multiple: Bool
        public let votesCount: Int
        /// nil if `multiple` is false
        public let votersCount: Int?
        /// nil if no current user
        public let voted: Bool?
        /// nil if no current user
        public let ownVotes: [Int]?
        public let options: [Option]
        
        enum CodingKeys: String, CodingKey {
            case id
            case expiresAt = "expires_at"
            case expired
            case multiple
            case votesCount = "votes_count"
            case votersCount = "voters_count"
            case voted
            case ownVotes = "own_votes"
            case options
        }
    }
}

extension Mastodon.Entity.Poll {
    public struct Option: Codable {
        public let title: String
        /// nil if results are not published yet
        public let votesCount: Int?
        public let emojis: [Mastodon.Entity.Emoji]
        
        enum CodingKeys: String, CodingKey {
            case title
            case votesCount = "votes_count"
            case emojis
        }
    }
}
