//
//  Mastodon+Entity+Quote.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 8/11/25.
//

import Foundation
import UIKit
import MastodonLocalization

extension Mastodon.Entity {
    
    /// Quote
    ///
    /// - Since: 4.4.0
    /// - Version: 4.4.0
    /// # Last Update
    ///   2025/08/11
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/Quote/)
    ///  [Document](https://docs.joinmastodon.org/entities/ShallowQuote/)
    public final class Quote: Codable, Sendable {
        public let state: AcceptanceState
        public let quotedStatusID: String? // if ShallowQuote, we will only get the id
        public let quotedStatus: Status?   // if Quote, we will get the Status (and not the id separately)
        
        enum CodingKeys: String, CodingKey {
            case state
            case quotedStatus = "quoted_status"
            case quotedStatusID = "quoted_status_id"
        }
    }
}

extension Mastodon.Entity.Quote {
    public enum AcceptanceState: RawRepresentable, Codable, Hashable, Sendable {
        case pending
        case accepted
        case rejected
        case revoked
        case deleted
        case unauthorized
        
        case _other(String)

        public init?(rawValue: String) {
            switch rawValue {
            case "pending":         self = .pending
            case "accepted":        self = .accepted
            case "rejected":        self = .rejected
            case "revoked":         self = .revoked
            case "deleted":         self = .deleted
            case "unauthorized":    self = .unauthorized
            default:                self = ._other(rawValue)
            }
        }

        public var rawValue: String {
            switch self {
            case .pending:              return "pending"
            case .accepted:             return "accepted"
            case .rejected:             return "rejected"
            case .revoked:              return "revoked"
            case .deleted:              return "deleted"
            case .unauthorized:         return "unauthorized"
            case ._other(let value):    return value
            }
        }
    }
}
