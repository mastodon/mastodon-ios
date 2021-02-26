//
//  Mastodon+Entity+Preferences.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import Foundation

extension Mastodon.Entity {
    /// Preferences
    ///
    /// - Since: 2.8.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/preferences/)
    public struct Preferences: Codable {
        public let postingDefaultVisibility: Visibility
        public let postingDefaultSensitive: Bool
        public let postingDefaultLanguage: String?      // (ISO 639-1 language two-letter code)
        public let readingExpandMedia: ExpandMedia
        public let readingExpandSpoilers: Bool
    }
}

extension Mastodon.Entity.Preferences {
    public typealias Visibility = Mastodon.Entity.Source.Privacy
}

extension Mastodon.Entity.Preferences {
    public enum ExpandMedia: RawRepresentable, Codable {
        case `default`
        case showAll
        case hideAll
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "default":                 self = .default
            case "showAll":                 self = .showAll
            case "hideAll":                 self = .hideAll
            default:                        self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .default:                      return "default"
            case .showAll:                      return "showAll"
            case .hideAll:                      return "hideAll"
            case ._other(let value):            return value
            }
        }
    }
}
