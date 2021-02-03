//
//  Mastodon+Entity+Results.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import Foundation

extension Mastodon.Entity {
    /// Results (v1)
    ///
    /// - Since: ?
    /// - Version: 3.0.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/results/)
    public struct Results: Codable {
        public let accounts: [Account]
        public let statuses: [Status]
        public let hashtags: [String]
    }
}

extension Mastodon.Entity.V2 {
    /// Results (v2)
    ///
    /// - Since: 2.4.1
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/results/)
    public struct Results: Codable {
        public let accounts: [Mastodon.Entity.Account]
        public let statuses: [Mastodon.Entity.Status]
        public let hashtags: [Mastodon.Entity.Tag]
    }
}

