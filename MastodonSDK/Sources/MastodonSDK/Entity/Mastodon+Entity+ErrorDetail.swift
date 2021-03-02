//
//  Mastodon+Entity+ErrorDetail.swift
//
//
//  Created by sxiaojian on 2021/3/1.
//

import Foundation
extension Mastodon.Entity.Error {
    /// ERR_BLOCKED    When e-mail provider is not allowed
    /// ERR_UNREACHABLE    When e-mail address does not resolve to any IP via DNS (MX, A, AAAA)
    /// ERR_TAKEN    When username or e-mail are already taken
    /// ERR_RESERVED    When a username is reserved, e.g. "webmaster" or "admin"
    /// ERR_ACCEPTED    When agreement has not been accepted
    /// ERR_BLANK    When a required attribute is blank
    /// ERR_INVALID    When an attribute is malformed, e.g. wrong characters or invalid e-mail address
    /// ERR_TOO_LONG    When an attribute is over the character limit
    /// ERR_INCLUSION    When an attribute is not one of the allowed values, e.g. unsupported locale
    public enum SignUpError: RawRepresentable, Codable {
        case ERR_BLOCKED
        case ERR_UNREACHABLE
        case ERR_TAKEN
        case ERR_RESERVED
        case ERR_ACCEPTED
        case ERR_BLANK
        case ERR_INVALID
        case ERR_TOO_LONG
        case ERR_TOO_SHORT
        case ERR_INCLUSION
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
extension Mastodon.Entity {
    public struct ErrorDetail: Codable {
        public let username: [ErrorDetailReason]?
        public let email: [ErrorDetailReason]?
        public let password: [ErrorDetailReason]?
        public let agreement: [ErrorDetailReason]?
        public let locale: [ErrorDetailReason]?
        public let reason: [ErrorDetailReason]?

        enum CodingKeys: String, CodingKey {
            case username
            case email
            case password
            case agreement
            case locale
            case reason
        }
    }

    public struct ErrorDetailReason: Codable {
        public init(error: String, errorDescription: String?) {
            self.error = Mastodon.Entity.Error.SignUpError(rawValue: error) ?? ._other(error)
            self.errorDescription = errorDescription
        }
        
        public let error: Mastodon.Entity.Error.SignUpError
        public let errorDescription: String?

        
        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "description"
        }
    }
}
