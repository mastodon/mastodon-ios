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
        public let role: Role?
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

        case createdAt = "created_at"
        case lastStatusAt = "last_status_at"
        case statusesCount = "statuses_count"
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case moved
        
        case fields
        case bot
        case source
        case role
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
        return lhs.acctWithDomain == rhs.acctWithDomain
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

extension Mastodon.Entity.Account {
    public final class Role: Codable, Sendable {
        public let id: String
        public let name: String
        public let color: String
        public let permissions: String // To determine the permissions available to a certain role, convert the permissions attribute to binary and compare from the least significant bit upwards.
        public let highlighted: Bool
        
        public func rolePermissions() -> Permissions {
            guard let rawValue = UInt32(permissions) else { return [] }
            return Permissions(rawValue: rawValue)
        }
        
        public struct Permissions: OptionSet {
            public let rawValue: UInt32
            
            public init(rawValue: UInt32) {
                self.rawValue = rawValue
            }
            
            public static let administrator = Permissions(rawValue: 1 << 0)
            public static let devops = Permissions(rawValue: 1 << 1)
            public static let viewAuditLog = Permissions(rawValue: 1 << 2)
            public static let viewDashboard = Permissions(rawValue: 1 << 3)
            
            public static let manageReports = Permissions(rawValue: 1 << 4)
            public static let manageFederation = Permissions(rawValue: 1 << 5)
            public static let manageSettings = Permissions(rawValue: 1 << 6)
            public static let manageBlocks = Permissions(rawValue: 1 << 7)
            
            public static let manageTaxonomies = Permissions(rawValue: 1 << 8)
            public static let manageAppeals = Permissions(rawValue: 1 << 9)
            public static let manageUsers = Permissions(rawValue: 1 << 10)
            public static let manageInvites = Permissions(rawValue: 1 << 11)
            
            public static let manageRules = Permissions(rawValue: 1 << 12)
            public static let manageAnnouncements = Permissions(rawValue: 1 << 13)
            public static let manageCustomEmojis = Permissions(rawValue: 1 << 14)
            public static let manageWebhooks = Permissions(rawValue: 1 << 15)
            
            public static let inviteUsers = Permissions(rawValue: 1 << 16)
            public static let manageRoles = Permissions(rawValue: 1 << 17)
            public static let manageUserAccess = Permissions(rawValue: 1 << 18)
            public static let deleteUserData = Permissions(rawValue: 1 << 19)
        }
    }
}
