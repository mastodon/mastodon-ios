//
//  Mastodon+Entity+Status.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation
import UIKit
import MastodonLocalization

extension Mastodon.Entity {
        
    /// Status
    ///
    /// - Since: 0.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/23
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/status/)
    public final class Status: Codable, Sendable {
        
        public typealias ID = String

        // Base
        public let id: ID
        public let uri: String
        public let createdAt: Date
        public let editedAt: Date?
        public let account: Account
        public let content: String? // will be optional when delete status
        
        public let sensitive: Bool?
        public let spoilerText: String?
        public let mediaAttachments: [Attachment]?
        public let application: Application?
        
        // Permissions
        public let visibility: Visibility?
        public let quoteApproval: QuoteApprovalInfo?
        
        // Rendering
        public let mentions: [Mention]
        public let tags: [Tag]
        public let emojis: [Emoji]
        
        // Informational
        public let reblogsCount: Int
        public let favouritesCount: Int
        public let repliesCount: Int?
        
        public let url: String?
        public let inReplyToID: Status.ID?
        public let inReplyToAccountID: Account.ID?
        public let reblog: Status?
        public let quote: Quote?
        public let poll: Poll?
        public let card: Card?
        public let language: String?        //  (ISO 639 Part 1 two-letter language code)
        public let text: String?
        
        public let filtered: [ServerFilterResult]?
        
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
            case editedAt = "edited_at"
            case account
            case content
            
            case sensitive
            case spoilerText = "spoiler_text"
            case mediaAttachments = "media_attachments"
            case application
            
            case visibility
            case quoteApproval = "quote_approval"
            
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
            case quote
            case poll
            case card
            case language
            case text
            
            case filtered

            case favourited
            case reblogged
            case muted
            case bookmarked
            case pinned
        }
    }
    
}

extension Mastodon.Entity.Status {
    public enum Visibility: RawRepresentable, Codable, Hashable, Sendable {
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

        public var title: String {
            switch self {
            case .public:               return L10n.Scene.Compose.Visibility.public
            case .unlisted:             return L10n.Scene.Compose.Visibility.unlisted
            case .private:              return L10n.Scene.Compose.Visibility.private
            case .direct:               return L10n.Scene.Compose.Visibility.direct
            case ._other(let value):    return value
            }
        }

        public var image: UIImage {
            switch self {
            case .public:       return UIImage(systemName: "globe.europe.africa")!.withRenderingMode(.alwaysTemplate)
            case .unlisted:     return UIImage(systemName: "moon")!.withRenderingMode(.alwaysTemplate)
            case .private:      return UIImage(systemName: "lock")!.withRenderingMode(.alwaysTemplate)
            case .direct:       return UIImage(systemName: "at")!.withRenderingMode(.alwaysTemplate)
            case ._other:       return UIImage(systemName: "ellipsis")!.withRenderingMode(.alwaysTemplate)
            }
        }

    }
}

extension Mastodon.Entity.Status {
    public final class QuoteApprovalInfo: Codable, Sendable {
        public let automatic: [QuotePermissionUserCategory]? // the API also includes `manual`, but we do not implement that option
        public let currentUser: CurrentUserQuotePermission?
        
        enum CodingKeys: String, CodingKey {
            case automatic
            case currentUser = "current_user"
        }
    }
}

extension Mastodon.Entity.Status {
    public enum QuotePermissionUserCategory: RawRepresentable, Codable, Hashable, Sendable {
        case anyone
        case followersOnly
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "public":              self = .anyone
            case "followers":           self = .followersOnly
                
            default:                    self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .anyone:               "public"
            case .followersOnly:        "followers"
            case ._other(let raw):      raw
            }
        }
    }
    
    public enum CurrentUserQuotePermission: RawRepresentable, Codable, Hashable, Sendable {
        case automatic
        case manual
        case unsupportedPolicy
        case denied

        case _other(String)

        public init?(rawValue: String) {
            switch rawValue {
            case "automatic":           self = .automatic
            case "manual":              self = .manual
            case "unsupported_policy":  self = .unsupportedPolicy
            case "denied":              self = .denied
                
            default:                    self = ._other(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .automatic:             return "automatic"
            case .manual:                return "manual"
            case .unsupportedPolicy:     return "unsupported_policy"
            case .denied:                return "denied"
            case ._other(let value):     return value
            }
        }
    }
}

extension Mastodon.Entity.Status: Hashable {
    public static func == (lhs: Mastodon.Entity.Status, rhs: Mastodon.Entity.Status) -> Bool {
        lhs.uri == rhs.uri &&
        lhs.id == rhs.id &&
        lhs.reblog == rhs.reblog &&
        lhs.favourited == rhs.favourited &&
        lhs.reblogged == rhs.reblogged &&
        lhs.bookmarked == rhs.bookmarked &&
        lhs.pinned == rhs.pinned &&
        lhs.content == rhs.content
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
        hasher.combine(id)
        hasher.combine(reblog)
        hasher.combine(favourited)
        hasher.combine(reblogged)
        hasher.combine(bookmarked)
        hasher.combine(pinned)
        hasher.combine(content)
    }
}
