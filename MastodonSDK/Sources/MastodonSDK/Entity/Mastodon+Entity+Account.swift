//
//  Mastodon+Entity+Account.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation
import MastodonCommon

extension Mastodon.Entity {

    /// Account
    ///
    /// - Since: 0.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/account/)
    public final class Account: Sendable {
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
        public let emojis: [Emoji]
        public let discoverable: Bool?
        public let hideCollections: Bool?
        public let indexable: Bool?

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
    }
}

//MARK: - Codable
extension Mastodon.Entity.Account: Codable {
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
        case hideCollections = "hide_collections"
        case indexable
        
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

//MARK: - Hashable
extension Mastodon.Entity.Account: Hashable {
    public func hash(into hasher: inout Hasher) {
        // The URL seems to be the only thing that doesn't change across instances.
        hasher.combine(url)
    }

}

//MARK: - Equatable
extension Mastodon.Entity.Account: Equatable {
    public static func == (lhs: Mastodon.Entity.Account, rhs: Mastodon.Entity.Account) -> Bool {
        // The URL seems to be the only thing that doesn't change across instances.
        return lhs.url == rhs.url
    }
}

//MARK: - Convenience
extension Mastodon.Entity.Account {
    public var acctWithDomain: String {
        if !acct.contains("@") {
            // Safe concat due to username cannot contains "@"
            return username + "@" + (domain ?? "")
        } else {
            return acct
        }
    }
    
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

    public func headerImageURL() -> URL? {
        let string = UserDefaults.shared.preferredStaticAvatar ? headerStatic ?? header : header
        return URL(string: string)
    }

    public func avatarImageURL() -> URL? {
        let string = UserDefaults.shared.preferredStaticAvatar ? avatarStatic ?? avatar : avatar
        return URL(string: string)
    }

    public func avatarImageURLWithFallback(domain: String) -> URL {
        return avatarImageURL() ?? URL(string: "https://\(domain)/avatars/original/\(Self.missingImageName)")!
    }

    public var displayNameWithFallback: String {
        return !displayName.isEmpty ? displayName : username

    }

    public var domainFromAcct: String? {
        if acct.contains("@") == false {
            return domain
        } else if let domain = acct.split(separator: "@").last {
            return String(domain)
        } else {
            return nil
        }
    }

}

extension Mastodon.Entity.Account {
    public static let missingImageName = "missing.png"
}
