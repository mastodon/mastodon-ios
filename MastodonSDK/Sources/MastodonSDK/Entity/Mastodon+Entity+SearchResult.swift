//
//  File.swift
//  
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
extension Mastodon.Entity {
    public struct SearchResult: Codable, Sendable {
        public init(accounts: [Mastodon.Entity.Account], statuses: [Mastodon.Entity.Status], hashtags: [Mastodon.Entity.Tag]) {
            self.accounts = accounts
            self.statuses = statuses
            self.hashtags = hashtags
        }
        
        public let accounts: [Mastodon.Entity.Account]
        public let statuses: [Mastodon.Entity.Status]
        public let hashtags: [Mastodon.Entity.Tag]
    }
    
}
