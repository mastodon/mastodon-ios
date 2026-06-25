//
//  Mastodon+Entity+Suggestion.swift
//  
//
//  Created by sxiaojian on 2021/4/20.
//

import Foundation

extension Mastodon.Entity.V2 {

    public struct SuggestionAccount: Codable, Sendable, Hashable {

        public let source: SuggestionReason?
        public let sources: [SuggestionReason]?
        public let account: Mastodon.Entity.Account
        
        
        enum CodingKeys: String, CodingKey {
            case source
            case sources
            case account
        }
        
        public enum SuggestionReason: String, Codable, Sendable {
            // Values returned for "source"; deprecated as of 4.3
            case staff /// This account was manually recommended by the administration team
            case pastInterations = "past_interactions" /// The authenticated account has interacted with this account previously
            case global /// This account has many reblogs, favourites, and active local followers within the last 30 days
            
            // Values returned in "sources"; available as of 4.3
            case featured  /// This account was manually recommended by the administration team. Equivalent to the deprecated 'staff'.
            case most_followed  /// This account has many active local followers
            case most_interactions /// This account had many reblogs and favourites within the last 30 days
            case similar_to_recently_followed /// This account’s profile is similar to the authenticated account’s most recent follows
            case friends_of_friends /// This account is followed by people followed by the authenticated account
        }
    }
}
