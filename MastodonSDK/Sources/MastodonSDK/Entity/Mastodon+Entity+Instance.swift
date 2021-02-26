//
//  Mastodon+Entity+Instance.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation

extension Mastodon.Entity {
    /// Instance
    ///
    /// - Since: 1.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/22
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/instance/)
    public struct Instance: Codable {
        
        public let uri: String
        public let title: String
        public let description: String
        public let shortDescription: String?
        public let email: String
        public let version: String?
        public let languages: [String]?     // (ISO 639 Part 1-5 language codes)
        public let registrations: Bool?
        public let approvalRequired: Bool?
        public let invitesEnabled: Bool?
        public let urls: InstanceURL?
        public let statistics: Statistics?
        
        public let thumbnail: String?
        public let contactAccount: Account?
        public let rules: [Rule]?

        enum CodingKeys: String, CodingKey {
            case uri
            case title
            case description
            case shortDescription = "short_description"
            case email
            case version
            case languages
            case registrations
            case approvalRequired = "approval_required"
            case invitesEnabled = "invites_enabled"
            case urls
            case statistics
            
            case thumbnail
            case contactAccount = "contact_account"
            case rules
        }
    }
}

extension Mastodon.Entity.Instance {
    public struct InstanceURL: Codable {
        public let streamingAPI: String

        enum CodingKeys: String, CodingKey {
            case streamingAPI = "streaming_api"
        }
    }
}

extension Mastodon.Entity.Instance {
    public struct Statistics: Codable {
        public let userCount: Int
        public let statusCount: Int
        public let domainCount: Int
        
        enum CodingKeys: String, CodingKey {
            case userCount = "user_count"
            case statusCount = "status_count"
            case domainCount = "domain_count"
        }
    }
}

extension Mastodon.Entity.Instance {
    public struct Rule: Codable {
        public let id: String
        public let text: String
    }
}
