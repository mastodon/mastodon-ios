//
//  Mastodon+Entity+Server.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-18.
//

import Foundation

extension Mastodon.Entity {
    
    public struct Server: Codable {
        public let domain: String
        public let version: String
        public let description: String
        public let languages: [String]
        public let region: String
        public let categories: [String]
        public let proxiedThumbnail: String
        public let totalUsers: Int
        public let lastWeekUsers: Int
        public let approvalRequired: Bool
        public let language: String
        public let category: String

        enum CodingKeys: String, CodingKey {
            case domain
            case version
            case description
            case languages
            case region
            case categories
            case proxiedThumbnail = "proxied_thumbnail"
            case totalUsers = "total_users"
            case lastWeekUsers = "last_week_users"
            case approvalRequired = "approval_required"
            case language
            case category
        }
    }
    
}
