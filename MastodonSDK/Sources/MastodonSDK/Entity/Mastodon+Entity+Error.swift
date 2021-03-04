//
//  Mastodon+Entity+Error.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// Error
    ///
    /// - Since: 0.6.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/4
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/error/)
    public struct Error: Codable {
        public let error: String
        public let errorDescription: String?
        public let details: Detail?
        
        enum CodingKeys: String, CodingKey {
            case error
            case errorDescription = "error_description"
            case details
        }
    }
}
