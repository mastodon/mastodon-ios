//
//  Mastodon+Entity+Status.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Entity {
        
    /// Status
    ///
    /// - Since: 0.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/23
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/status/)
    public class Status: Codable {
        
        public typealias ID = String

        // Base
        public let id: ID
        public let uri: String
        public let createdAt: Date
        public let account: Account
        public let content: String? // will be optional when delete status
        
        public let visibility: Visibility?
        public let sensitive: Bool?
        public let spoilerText: String?
        public let mediaAttachments: [Attachment]?
        public let application: Application?
        
        // Rendering
        public let mentions: [Mention]?
        public let tags: [Tag]?
        public let emojis: [Emoji]?
        
        // Informational
        public let reblogsCount: Int
        public let favouritesCount: Int
        public let repliesCount: Int?
        
        public let url: String?
        public let inReplyToID: Status.ID?
        public let inReplyToAccountID: Account.ID?
        public let reblog: Status?
        public let poll: Poll?
        public let card: Card?
        public let language: String?        //  (ISO 639 Part 1 two-letter language code)
        public let text: String?
        
        // Authorized user
        public let favourited: Bool?
        public let reblogged: Bool?
        public let muted: Bool?
        public let bookmarked: Bool?
        public let pinned: Bool?
        
        
        enum CodingKeys: String, CodingKey {
            case id
            case uri
            case createdAt = "created_at"
            case account
            case content
            
            case visibility
            case sensitive
            case spoilerText = "spoiler_text"
            case mediaAttachments = "media_attachments"
            case application
            
            case mentions
            case tags
            case emojis
            
            case reblogsCount = "reblogs_count"
            case favouritesCount = "favourites_count"
            case repliesCount = "replies_count"
            
            case url
            case inReplyToID = "in_reply_to_id"
            case inReplyToAccountID = "in_reply_to_account_id"
            case reblog
            case poll
            case card
            case language
            case text

            case favourited
            case reblogged
            case muted
            case bookmarked
            case pinned
        }
    }
    
}

extension Mastodon.Entity.Status {
    public enum Visibility: RawRepresentable, Codable, Hashable {
        case `public`
        case unlisted
        case `private`
        case direct
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "public":                      self = .public
            case "unlisted":                    self = .unlisted
            case "private":                     self = .private
            case "direct":                      self = .direct
            default:                            self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .public:                       return "public"
            case .unlisted:                     return "unlisted"
            case .private:                      return "private"
            case .direct:                       return "direct"
            case ._other(let value):            return value
            }
        }
    }
}
