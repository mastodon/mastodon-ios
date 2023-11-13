//
//  Mastodon+Entity+Account.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Entity {
    
    /// Account
    ///
    /// - Since: 0.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/account/)
    public final class Account: Codable, Sendable {

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
        public let avatarStatic: String?
        public let header: String
        public let headerStatic: String?
        public let locked: Bool
        public let emojis: [Emoji]?
        public let discoverable: Bool?
        
        // Statistical
        public let createdAt: Date
        public let lastStatusAt: Date?
        public let statusesCount: Int
        public let followersCount: Int
        public let followingCount: Int
        
        public let moved: Account?
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

extension Mastodon.Entity.Account: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(username)
        hasher.combine(acct)
        hasher.combine(url)
        hasher.combine(displayName)
        hasher.combine(note)
        hasher.combine(avatar)
        hasher.combine(avatarStatic)
        hasher.combine(header)
        hasher.combine(headerStatic)
        hasher.combine(locked)
        hasher.combine(emojis)
        hasher.combine(discoverable)
        hasher.combine(createdAt)
        hasher.combine(lastStatusAt)
        hasher.combine(statusesCount)
        hasher.combine(followersCount)
        hasher.combine(followingCount)
        hasher.combine(moved)
        hasher.combine(fields)
        hasher.combine(bot)
        hasher.combine(source)
        hasher.combine(suspended)
        hasher.combine(muteExpiresAt)
    }
}

extension Mastodon.Entity.Account: Equatable {
    public static func == (lhs: Mastodon.Entity.Account, rhs: Mastodon.Entity.Account) -> Bool {
        return lhs.id == rhs.id &&
        lhs.username == rhs.username &&
        lhs.acct == rhs.acct &&
        lhs.url == rhs.url &&
        lhs.displayName == rhs.displayName &&
        lhs.note == rhs.note &&
        lhs.avatar == rhs.avatar &&
        lhs.avatarStatic == rhs.avatarStatic &&
        lhs.header == rhs.header &&
        lhs.headerStatic == rhs.headerStatic &&
        lhs.locked == rhs.locked &&
        lhs.emojis == rhs.emojis &&
        lhs.discoverable == rhs.discoverable &&
        lhs.createdAt == rhs.createdAt &&
        lhs.lastStatusAt == rhs.lastStatusAt &&
        lhs.statusesCount == rhs.statusesCount &&
        lhs.followersCount == rhs.followersCount &&
        lhs.followingCount == rhs.followingCount &&
        lhs.moved == rhs.moved &&
        lhs.fields == rhs.fields &&
        lhs.bot == rhs.bot &&
        lhs.source == rhs.source &&
        lhs.suspended == rhs.suspended &&
        lhs.muteExpiresAt == rhs.muteExpiresAt
    }
}

extension Mastodon.Entity.Account {
    public func acctWithDomainIfMissing(_ localDomain: String) -> String {
        guard acct.contains("@") else {
            return "\(acct)@\(localDomain)"
        }
        return acct
    }

    public var verifiedLink: Mastodon.Entity.Field? {
        let firstVerified = fields?.first(where: { $0.verifiedAt != nil })
        return firstVerified
    }

    public var domain: String? {
        guard let components = URLComponents(string: url) else { return nil }

        return components.host
    }
}
