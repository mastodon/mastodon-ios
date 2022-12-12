//
//  Mastodon+Entity+Translation.swift
//  
//
//  Created by Marcus Kida on 02.12.22.
//

import Foundation

extension Mastodon.Entity {
    public struct Translation: Codable {
        public let content: String?
        public let sourceLanguage: String?
        public let provider: String?
        
        enum CodingKeys: String, CodingKey {
            case content
            case sourceLanguage = "detected_source_language"
            case provider
        }
    }
}
