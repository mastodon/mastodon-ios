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
    public struct Notification: Codable {
        public typealias ID = String
        
        public let id: ID
        public let type: Type
        public let createdAt: Date
        public let account: Account
        
        public let status: Status?
        
        enum CodingKeys: String, CodingKey {
            case id
            case type
            case createdAt = "created_at"
            case account
            case status
        }
    }
}

extension Mastodon.Entity.Notification {
    public enum `Type`: RawRepresentable, Codable {
        case follow
        case followRequest
        case mention
        case reblog
        case favourite
        case poll
        case status
        
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
            case ._other(let value):            return value
            }
        }
    }
}
