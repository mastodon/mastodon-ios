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
    public struct Card: Codable {
        // Base
        public let url: String
        public let title: String
        public let description: String
        public let type: Type?
        
        public let authorName: String?
        public let authorURL: String?
        public let providerName: String?
        public let providerURL: String?
        public let html: String?
        public let width: Int?
        public let height: Int?
        public let image: String?
        public let embedURL: String?
        public let blurhash: String?
        
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
        }
    }
}

extension Mastodon.Entity.Card {
    public enum `Type`: String, Codable {
        case link
        case photo
        case video
        case rich
    }
}
