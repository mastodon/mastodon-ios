//
//  Mastodon+Entity+Field.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Field
    ///
    /// - Since: 2.4.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/field/)
    public struct Field: Codable, Sendable, Hashable {
        public let name: String
        public let value: String
        
        public let verifiedAt: Date?
        
        enum CodingKeys: String, CodingKey {
            case name
            case value
            case verifiedAt = "verified_at"
        }
        
        public init(name: String, value: String, verifiedAt: Date? = nil) {
            self.name = name
            self.value = value
            self.verifiedAt = verifiedAt
        }
    }
}
