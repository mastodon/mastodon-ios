//
//  Mastodon+Entity+Context.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Context
    ///
    /// - Since: 0.6.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/context/)
    public struct Context: Codable, Sendable {
        public let ancestors: [Status]
        public let descendants: [Status]
    }
}
