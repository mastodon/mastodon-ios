import Foundation

extension Mastodon.Entity.V2 {
    /// Instance
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.3
    /// # Last Update
    ///   2022/12/09
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/instance/)
    public struct Instance: Codable {

        public let domain: String?
        public let title: String
        public let description: String
        public let shortDescription: String?
        public let version: String?
        public let languages: [String]?     // (ISO 639 Part 1-5 language codes)
        public let registrations: Mastodon.Entity.V2.Instance.Registrations?
        public let approvalRequired: Bool?
        public let invitesEnabled: Bool?
        public let urls: Mastodon.Entity.Instance.InstanceURL?
        public let statistics: Mastodon.Entity.Instance.Statistics?
        
        public let thumbnail: Thumbnail?
        public let contact: Mastodon.Entity.V2.Instance.Contact?
        public let rules: [Mastodon.Entity.Instance.Rule]?
        
        // https://github.com/mastodon/mastodon/pull/16485
        public let configuration: Configuration?

        public init(domain: String, approvalRequired: Bool? = nil) {
            self.domain = domain
            self.title = domain
            self.description = ""
            self.shortDescription = nil
            self.contact = nil
            self.version = nil
            self.languages = nil
            self.registrations = nil
            self.approvalRequired = approvalRequired
            self.invitesEnabled = nil
            self.urls = nil
            self.statistics = nil
            self.thumbnail = nil
            self.rules = nil
            self.configuration = nil
        }

        enum CodingKeys: String, CodingKey {
            case domain
            case title
            case description
            case shortDescription = "short_description"
            case version
            case languages
            case registrations
            case approvalRequired = "approval_required"
            case invitesEnabled = "invites_enabled"
            case urls
            case statistics = "stats"
            
            case thumbnail
            case contact
            case rules
            
            case configuration
        }
    }
}

extension Mastodon.Entity.V2.Instance {
    public struct Configuration: Codable, InstanceConfigLimitingPropertyContaining {
        public let statuses: Mastodon.Entity.Instance.Configuration.Statuses?
        public let mediaAttachments: Mastodon.Entity.Instance.Configuration.MediaAttachments?
        public let polls: Mastodon.Entity.Instance.Configuration.Polls?
        public let translation: Mastodon.Entity.V2.Instance.Configuration.Translation?
    
        enum CodingKeys: String, CodingKey {
            case statuses
            case mediaAttachments = "media_attachments"
            case polls
            case translation
        }
    }
}

extension Mastodon.Entity.V2.Instance {
    public struct Registrations: Codable {
        public let enabled: Bool
    }
}

extension Mastodon.Entity.V2.Instance.Configuration {
    public struct Translation: Codable {
        public let enabled: Bool
    }
}

extension Mastodon.Entity.V2.Instance {
    public struct Thumbnail: Codable {
        public let url: String?
    }
}

extension Mastodon.Entity.V2.Instance {
    public struct Contact: Codable {
        public let email: String?
        public let account: Mastodon.Entity.Account?
    }
}

extension Mastodon.Entity.V2.Instance: Hashable {
    public static func == (lhs: Mastodon.Entity.V2.Instance, rhs: Mastodon.Entity.V2.Instance) -> Bool {
        lhs.domain == rhs.domain
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(domain)
    }
}
