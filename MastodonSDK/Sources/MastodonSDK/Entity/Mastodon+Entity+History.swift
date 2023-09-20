//
//  Mastodon+Entity+History.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// History
    ///
    /// - Since: 2.4.1
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/history/)
    public struct History: Hashable, Codable, Sendable {
        /// UNIX timestamp on midnight of the given day
        public let day: Date
        public let uses: String
        public let accounts: String
    }
}
