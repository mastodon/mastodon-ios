//
//  Mastodon+Entity+Notification.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import Foundation

extension Mastodon.Entity {
    /// Notification
    ///
    /// - Since: 0.9.9
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/notification/)
    public struct Notification: Codable, Sendable {
        public typealias ID = String
        
        public let id: ID
        public let type: Type
        public let createdAt: Date
        public let account: Account
        public let status: Status?
        public let accountWarning: AccountWarning?

        enum CodingKeys: String, CodingKey {
            case id
            case type
            case createdAt = "created_at"
            case account
            case status
            case accountWarning = "moderation_warning"
        }
    }
}

extension Mastodon.Entity {
    public struct AccountWarning: Codable {
        public typealias ID = String

        public let id: ID
        public let action: Action
        public let text: String?
        public let targetAccount: Account
        public let appeal: Appeal?
        public let statusIds: [Mastodon.Entity.Status.ID]?

        public enum CodingKeys: String, CodingKey {
            case id
            case action
            case text
            case targetAccount = "target_account"
            case appeal
            case statusIds = "status_ids"
        }

        public enum Action: String, Codable {
            case none
            case disable
            case markStatusesAsSensitive
            case deleteStatuses
            case sensitive
            case silence
            case suspend

            public enum CodingKeys: String, CodingKey {
                case none
                case disable
                case markStatusesAsSensitive = "mark_statuses_as_sensitive"
                case deleteStatuses = "delete_statuses"
                case sensitive
                case silence
                case suspend
            }
        }

        public struct Appeal: Codable {
            public let text: String
            public let state: State

            public enum State: String, Codable {
                case approved
                case rejected
                case pending
            }
        }
    }
}

extension Mastodon.Entity.Notification {
    public typealias NotificationType = Type
    public enum `Type`: RawRepresentable, Codable, Sendable {
        case follow
        case followRequest
        case mention
        case reblog
        case favourite
        case poll
        case status
        case moderationWarning

        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "follow":              self = .follow
            case "follow_request":      self = .followRequest
            case "mention":             self = .mention
            case "reblog":              self = .reblog
            case "favourite":           self = .favourite
            case "poll":                self = .poll
            case "status":              self = .status
            case "moderation_warning":  self = .moderationWarning
            default:                    self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .follow:                       return "follow"
            case .followRequest:                return "follow_request"
            case .mention:                      return "mention"
            case .reblog:                       return "reblog"
            case .favourite:                    return "favourite"
            case .poll:                         return "poll"
            case .status:                       return "status"
            case .moderationWarning:            return "moderation_warning"
            case ._other(let value):            return value
            }
        }
    }
}

extension Mastodon.Entity.Notification: Hashable {
    public static func == (lhs: Mastodon.Entity.Notification, rhs: Mastodon.Entity.Notification) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
