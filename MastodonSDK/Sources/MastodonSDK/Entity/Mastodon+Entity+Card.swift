//
//  Mastodon+Entity+Card.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Card
    ///
    /// - Since: 1.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/card/)
    public struct Card: Codable, Sendable {
        // Base
        public let url: String
        public let title: String
        public let description: String
        public let type: Type

        @available(*, deprecated, message: "Use authors-array. Kept for compatibility")
        public let authorName: String?
        @available(*, deprecated, message: "Use authors-array. Kept for compatibility")
        public let authorURL: String?
        public let providerName: String?
        public let providerURL: String?
        public let html: String?
        public let width: Int?
        public let height: Int?
        public let image: String?
        public let embedURL: String?
        public let blurhash: String?
        public let authors: [Mastodon.Entity.Card.Author]?
        public let publishedAt: Date?

        enum CodingKeys: String, CodingKey {
            case url
            case title
            case description
            case type
            case authorName = "author_name"
            case authorURL = "author_url"
            case providerName = "provider_name"
            case providerURL = "provider_url"
            case html
            case width
            case height
            case image
            case embedURL = "embed_url"
            case blurhash
            case authors
            case publishedAt = "published_at"
        }
    }
}

extension Mastodon.Entity.Card {
    public struct Author: Codable, Sendable {
        public let name: String?
        public let url: String?
        public let account: Mastodon.Entity.Account?
    }
}

extension Mastodon.Entity.Card {
    public enum `Type`: RawRepresentable, Codable, Sendable {
        case link
        case photo
        case video
        case rich
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "link":        self = .link
            case "photo":       self = .photo
            case "video":       self = .video
            case "rich":        self = .rich
            default:            self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .link:                 return "link"
            case .photo:                return "photo"
            case .video:                return "video"
            case .rich:                 return "rich"
            case ._other(let value):    return value
            }
        }
    }
}

extension Mastodon.Entity.Card: Hashable {
    public static func == (lhs: Mastodon.Entity.Card, rhs: Mastodon.Entity.Card) -> Bool {
        lhs.url == rhs.url
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
