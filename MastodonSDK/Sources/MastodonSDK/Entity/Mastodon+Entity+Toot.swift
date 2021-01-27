//
//  Mastodon+Entity+Toot.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Entity {
    public struct Toot: Codable {
        
        public typealias ID = String

        public let id: ID

        public let createdAt: Date
        public let content: String
        public let account: User
        
        public let language: String
        public let visibility: String
        
        enum CodingKeys: String, CodingKey {
            case id
            case createdAt = "created_at"
            case content
            case account
            case language
            case visibility
        }
        
    }
}
