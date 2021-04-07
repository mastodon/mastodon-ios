//
//  File.swift
//  
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
extension Mastodon.Entity {
    public struct SearchResult: Codable {
        public let accounts: [Mastodon.Entity.Account]
        public let statuses: [Mastodon.Entity.Status]
        public let hashtags: [Mastodon.Entity.Tag]
    }
    
}
