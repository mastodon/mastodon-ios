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
        
        // https://github.com/mastodon/mastodon/pull/16485
        public let configuration: Configuration?

        public init(domain: String, approvalRequired: Bool? = nil) {
            self.uri = domain
            self.title = domain
            self.description = ""
            self.shortDescription = nil
            self.email = ""
            self.version = nil
            self.languages = nil
            self.registrations = nil
            self.approvalRequired = approvalRequired
            self.invitesEnabled = nil
            self.urls = nil
            self.statistics = nil
            self.thumbnail = nil
            self.contactAccount = nil
            self.rules = nil
            self.configuration = nil
        }

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
            case statistics = "stats"
            
            case thumbnail
            case contactAccount = "contact_account"
            case rules
            
            case configuration
        }
    }
}

extension Mastodon.Entity.Instance {
    public struct InstanceURL: Codable {
        public let streamingAPI: String?
        public let aboutPage: String?
        public let privacyPolicy: String?  // added in 4.4.0, default to https://(domain)/privacy_policy if empty
        public let termsOfService: String? // added in 4.4.0, default to nil if empty

        enum CodingKeys: String, CodingKey {
            case streamingAPI = "streaming_api"
            case aboutPage = "about"
            case privacyPolicy = "privacy_policy"
            case termsOfService = "terms_of_service"
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
    public struct Rule: Codable, Hashable {
        public typealias ID = String

        public let id: ID
        public let title: String // Prior to 4.3.0, the rule. After 4.3.0, the shorter-form/headline version of the rule.
        public let hint: String? // Longer-form description of the rule, added 4.3.0
        public let translations: [String : RuleTranslation]? // Added 4.4.0
        
        public struct RuleTranslation: Codable, Hashable {
            public let title: String
            public let hint: String?
            
            enum CodingKeys: String, CodingKey {
                case title = "text"
                case hint
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case id
            case title = "text"
            case hint
            case translations
        }
    }
}

extension Mastodon.Entity.Instance.Rule {
    public var possiblyTranslatedTitle: String {
        guard let translations, let deviceLanguage = Bundle.main.preferredLocalizations.first else { return title }
        return translations[deviceLanguage]?.title ?? title
    }
    public var possiblyTranslatedDetail: String? {
        guard let translations, let deviceLanguage = Bundle.main.preferredLocalizations.first else { return hint }
        return translations[deviceLanguage]?.hint ?? hint
    }
}

extension Mastodon.Entity.Instance {
    public struct Configuration: Codable, InstanceConfigLimitingPropertyContaining {
        public let statuses: Statuses?
        public let mediaAttachments: MediaAttachments?
        public let polls: Polls?
        public let accounts: Mastodon.Entity.V2.Instance.Configuration.AccountsLimits? = nil
        
        enum CodingKeys: String, CodingKey {
            case statuses
            case mediaAttachments = "media_attachments"
            case polls
        }
    }
}

extension Mastodon.Entity.Instance.Configuration {
    public struct Statuses: Codable {
        public let maxCharacters: Int
        public let maxMediaAttachments: Int
        public let charactersReservedPerURL: Int
        
        enum CodingKeys: String, CodingKey {
            case maxCharacters = "max_characters"
            case maxMediaAttachments = "max_media_attachments"
            case charactersReservedPerURL = "characters_reserved_per_url"
        }
    }
    
    public struct MediaAttachments: Codable {
        public let supportedMIMETypes: [String]
        public let imageSizeLimit: Int
        public let imageMatrixLimit: Int
        public let videoSizeLimit: Int
        public let videoFrameRateLimit: Int
        public let videoMatrixLimit: Int
        
        enum CodingKeys: String, CodingKey {
            case supportedMIMETypes = "supported_mime_types"
            case imageSizeLimit = "image_size_limit"
            case imageMatrixLimit = "image_matrix_limit"
            case videoSizeLimit = "video_size_limit"
            case videoFrameRateLimit = "video_frame_rate_limit"
            case videoMatrixLimit = "video_matrix_limit"
        }
    }
    
    public struct Polls: Codable {
        public let maxOptions: Int
        public let maxCharactersPerOption: Int
        public let minExpiration: Int
        public let maxExpiration: Int
        
        enum CodingKeys: String, CodingKey {
            case maxOptions = "max_options"
            case maxCharactersPerOption = "max_characters_per_option"
            case minExpiration = "min_expiration"
            case maxExpiration = "max_expiration"
        }
    }
}

extension Mastodon.Entity.Instance: Hashable {
    public static func == (lhs: Mastodon.Entity.Instance, rhs: Mastodon.Entity.Instance) -> Bool {
        lhs.uri == rhs.uri
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uri)
    }
}
