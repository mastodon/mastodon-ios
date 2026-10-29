//
//  Mastodon+Entity+FeatureApproval.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 10/29/26.
//

import Foundation

extension Mastodon.Entity {
    /// FeatureApproval
    ///
    /// - Since: 4.6.0
    /// # Reference
    /// [Document](https://docs.joinmastodon.org/entities/FeatureApproval/)
    public struct FeatureApproval: Codable, Sendable, Hashable {
        public let automatic: [String]
        public let manual: [String]
        public let currentUser: CurrentUserApproval
        
        enum CodingKeys: String, CodingKey {
            case automatic
            case manual
            case currentUser = "current_user"
        }
        
        public var currentUserCanFeature: Bool {
            switch currentUser {
            case .automatic, .manual: true
            case .denied, .unknown, .missing, ._other: false
            }
        }
    }
}

extension Mastodon.Entity.FeatureApproval {
    public enum CurrentUserApproval: RawRepresentable, Codable, Sendable, Hashable {
        case automatic
        case manual
        case denied
        case unknown
        case missing
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "automatic": self = .automatic
            case "manual": self = .manual
            case "denied": self = .denied
            case "unknown": self = .unknown
            case "missing": self = .missing
            default: self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .automatic: "automatic"
            case .manual: "manual"
            case .denied: "denied"
            case .unknown: "unknown"
            case .missing: "missing"
            case ._other(let string): string
            }
        }
    }
}
