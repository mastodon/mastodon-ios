import Foundation

extension Mastodon.Entity.V2 {
    /// Instance
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.3
    /// # Last Update
    ///   2025/03/24
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/instance/)
    public struct Instance: Codable {

        public let domain: String?
        public let title: String
        public let description: String
        public let shortDescription: String?
        public let version: String?
        public let apiVersions: [String : Int]?
        public let languages: [String]?     // (ISO 639 Part 1-5 language codes)
        public let registrations: Mastodon.Entity.V2.Instance.Registrations?
        public let invitesEnabled: Bool?
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
            self.apiVersions = nil
            self.languages = nil
            self.registrations = nil
            self.invitesEnabled = nil
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
            case apiVersions = "api_versions"
            case languages
            case registrations
            case invitesEnabled = "invites_enabled"
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
        public let urls: Mastodon.Entity.Instance.InstanceURL?
        public let mediaAttachments: Mastodon.Entity.Instance.Configuration.MediaAttachments?
        public let polls: Mastodon.Entity.Instance.Configuration.Polls?
        public let translation: Mastodon.Entity.V2.Instance.Configuration.Translation?
        public let timelinesAccess: Mastodon.Entity.V2.Instance.Configuration.TimelinesAccess?
        public let accounts: Mastodon.Entity.V2.Instance.Configuration.AccountsLimits?
    
        enum CodingKeys: String, CodingKey {
            case urls
            case statuses
            case mediaAttachments = "media_attachments"
            case polls
            case translation
            case timelinesAccess = "timelines_access"
            case accounts
        }
    }
}

extension Mastodon.Entity.V2.Instance.Configuration {
    public struct AccountsLimits: Codable {
        public let maxDisplayNameLength: Int?           // 4.6  default to 30
        public let maxBioLength: Int?                   // 4.6  default to 500 (prefer 220)
        public let maxFeaturedTagCount: Int?            // 4.0 default to 10
        public let maxPinnedStatusCount: Int?           // 4.3  default to 5
        public let maxProfileCustomFieldsCount: Int?    // 4.6  default to 4
        public let maxProfileFieldNameLength: Int?      // 4.6 default to 255
        public let maxProfileFieldValueLength: Int?     // 4.6 default to 255
        
        enum CodingKeys: String, CodingKey {
            case maxDisplayNameLength = "max_display_name_length"
            case maxBioLength = "max_note_length"
            case maxFeaturedTagCount = "max_featured_tags"
            case maxPinnedStatusCount = "max_pinned_statuses"
            case maxProfileCustomFieldsCount = "max_profile_fields"
            case maxProfileFieldNameLength = "profile_field_name_limit"
            case maxProfileFieldValueLength = "profile_field_value_limit"
        }
    }
}

extension Mastodon.Entity.V2.Instance {
    public struct Registrations: Codable {
        public let enabled: Bool
        public let minAge: Int?
        public let approvalRequired: Bool?
        public let reasonRequired: Bool?
        
        enum CodingKeys: String, CodingKey {
            case enabled
            case minAge = "min_age"
            case approvalRequired = "approval_required"
            case reasonRequired = "reason_required"
        }
    }
}

extension Mastodon.Entity.V2.Instance.Configuration {
    public struct Translation: Codable {
        public let enabled: Bool
    }
}

extension Mastodon.Entity.V2.Instance.Configuration {
    public struct TimelinesAccess: Codable, Sendable {
        public let liveFeeds: TimelinesAccessSetting?
        public let hashtagFeeds: TimelinesAccessSetting?
        public let trendingLinkFeeds: TimelinesAccessSetting?
        
        enum CodingKeys: String, CodingKey {
            case liveFeeds = "live_feeds"
            case hashtagFeeds = "hashtag_feeds"
            case trendingLinkFeeds = "trending_link_feeds"
        }
        
        public struct TimelinesAccessSetting: Codable, Sendable {
            public let localPosts: TimelineViewer?
            public let remotePosts: TimelineViewer?
            
            enum CodingKeys: String, CodingKey {
                case localPosts = "local"
                case remotePosts = "remote"
            }
        }
        
        public enum TimelineViewer: String, Codable, Sendable {
            case anyone = "public"
            case loggedInUsers = "authenticated"
            case usersWithRolePermission = "disabled"
        }
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
