//
//  Mastodon+Entity+User.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Entity {
    public struct User: Codable {
        
        public typealias ID = String

        public let id: ID

        public let username: Date
        public let acct: String
        public let displayName: String?
        public let avatar: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case username
            case acct
            case displayName = "display_name"
            case avatar
        }
        
    }
}
