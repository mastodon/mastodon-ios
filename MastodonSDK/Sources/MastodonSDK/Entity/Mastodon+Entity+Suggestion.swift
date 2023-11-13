//
//  Mastodon+Entity+Suggestion.swift
//  
//
//  Created by sxiaojian on 2021/4/20.
//

import Foundation

extension Mastodon.Entity.V2 {

    public struct SuggestionAccount: Codable, Sendable, Hashable {

        public let source: String
        public let account: Mastodon.Entity.Account
        
        
        enum CodingKeys: String, CodingKey {
            case source
            case account
        }
    }
}
