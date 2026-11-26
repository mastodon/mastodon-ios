//
//  Mastodon+Entity+FamiliarFollowers.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import Foundation

extension Mastodon.Entity {
    
    /// FamiliarFollowers
    ///
    /// - Since: 3.5.2
    /// - Version: 3.5.2
    /// # Last Update
    ///   2022/5/16
    /// # Reference
    ///  [Document](TBD)
    public final class FamiliarFollowers: Codable, Sendable {
        public let id: Mastodon.Entity.Account.ID
        public let accounts: [Mastodon.Entity.Account]
    }
}
