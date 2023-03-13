//
//  Mastodon+Entity+Activity.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Activity
    ///
    /// - Since: 2.1.2
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/activity/)
    public struct Activity: Codable, Sendable {
        public let week: Date
        public let statuses: Int
        public let logins: Int
        public let registrations: Int
    }
}
