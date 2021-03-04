//
//  Mastodon+Entity+ErrorDetail.swift
//
//
//  Created by sxiaojian on 2021/3/1.
//

import Foundation

extension Mastodon.Entity.Error {
    public struct Detail: Codable {
        public let username: [Reason]?
        public let email: [Reason]?
        public let password: [Reason]?
        public let agreement: [Reason]?
        public let locale: [Reason]?
        public let reason: [Reason]?

        enum CodingKeys: String, CodingKey {
            case username
            case email
            case password
            case agreement
            case locale
            case reason
        }
    }
}



extension Mastodon.Entity.Error.Detail {
    public struct Reason: Codable {
        public let error: Error
        public let description: String
        
        enum CodingKeys: String, CodingKey {
            case error
            case description
        }
    }
}

extension Mastodon.Entity.Error.Detail.Reason {
    /// - Since: 3.3.1
    /// - Version: 3.3.1
    /// # Last Update
    ///   2021/3/4
    /// # Reference
    ///   [Document](https://github.com/tootsuite/mastodon/pull/15803)
    public enum Error: RawRepresentable, Codable {
        /// When e-mail provider is not allowed
        case ERR_BLOCKED
        /// When e-mail address does not resolve to any IP via DNS (MX, A, AAAA)
        case ERR_UNREACHABLE
        /// When username or e-mail are already taken
        case ERR_TAKEN
        /// When a username is reserved, e.g. "webmaster" or "admin"
        case ERR_RESERVED
        /// When agreement has not been accepted
        case ERR_ACCEPTED
        /// When a required attribute is blank
        case ERR_BLANK
        /// When an attribute is malformed, e.g. wrong characters or invalid e-mail address
        case ERR_INVALID
        /// When an attribute is over the character limit
        case ERR_TOO_LONG
        /// When an attribute is under the character requirement
        case ERR_TOO_SHORT
        /// When an attribute is not one of the allowed values, e.g. unsupported locale
        case ERR_INCLUSION
        /// Not handled error
        case _other(String)

        public init?(rawValue: String) {
            switch rawValue {
            case "ERR_BLOCKED": self = .ERR_BLOCKED
            case "ERR_UNREACHABLE": self = .ERR_UNREACHABLE
            case "ERR_TAKEN": self = .ERR_TAKEN
            case "ERR_RESERVED": self = .ERR_RESERVED
            case "ERR_ACCEPTED": self = .ERR_ACCEPTED
            case "ERR_BLANK": self = .ERR_BLANK
            case "ERR_INVALID": self = .ERR_INVALID
            case "ERR_TOO_LONG": self = .ERR_TOO_LONG
            case "ERR_TOO_SHORT": self = .ERR_TOO_SHORT
            case "ERR_INCLUSION": self = .ERR_INCLUSION

            default:
                self = ._other(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .ERR_BLOCKED: return "ERR_BLOCKED"
            case .ERR_UNREACHABLE: return "ERR_UNREACHABLE"
            case .ERR_TAKEN: return "ERR_TAKEN"
            case .ERR_RESERVED: return "ERR_RESERVED"
            case .ERR_ACCEPTED: return "ERR_ACCEPTED"
            case .ERR_BLANK: return "ERR_BLANK"
            case .ERR_INVALID: return "ERR_INVALID"
            case .ERR_TOO_LONG: return "ERR_TOO_LONG"
            case .ERR_TOO_SHORT: return "ERR_TOO_SHORT"
            case .ERR_INCLUSION: return "ERR_INCLUSION"

            case ._other(let value): return value
            }
        }
    }
}
