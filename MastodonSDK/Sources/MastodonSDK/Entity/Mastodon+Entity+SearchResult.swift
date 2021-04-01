//
//  File.swift
//  
//
//  Created by sxiaojian on 2021/3/31.
//

import Foundation
extension Mastodon.Entity {
    public struct SearchResult: Codable {
        let accounts: [Mastodon.Entity.Account]
        let statuses: [Mastodon.Entity.Status]
        let hashtags: [Mastodon.Entity.Tag]
    }
    
}
