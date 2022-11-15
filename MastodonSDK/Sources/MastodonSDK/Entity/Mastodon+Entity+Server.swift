//
//  Mastodon+Entity+Server.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-18.
//

import Foundation

extension Mastodon.Entity {
    
    public struct Server: Codable, Equatable, Hashable {
        public let domain: String
        public let version: String
        public let description: String
        public let languages: [String]
        public let region: String
        public let categories: [String]
        public let proxiedThumbnail: String?
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
        
        public init(domain: String, instance: Instance) {
            self.domain = domain        // make domain configurable for WebFinger
            self.version = instance.version ?? ""
            self.description = instance.shortDescription ?? instance.description
            self.language = instance.languages?.first ?? ""
            self.languages = instance.languages ?? []
            self.region = "Unknown" // TODO: how to handle properties not in an instance
            self.categories = []
            self.category = "Unknown"
            self.proxiedThumbnail = instance.thumbnail
            self.totalUsers = instance.statistics?.userCount ?? 0
            self.lastWeekUsers = 0
            self.approvalRequired = instance.approvalRequired ?? false
        }
        
        public static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.domain.caseInsensitiveCompare(rhs.domain) == .orderedSame
        }
    }
    
}
