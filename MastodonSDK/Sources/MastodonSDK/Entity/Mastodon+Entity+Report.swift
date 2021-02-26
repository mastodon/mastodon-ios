//
//  Mastodon+Entity+Report.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/29.
//

import Foundation

extension Mastodon.Entity {
    /// Report
    ///
    /// - Since: ?
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/report/)
    public struct Report: Codable {
        public typealias ID = String
        
        public let id: ID                   //  undocumented
        public let actionTaken: Bool?       //  undocumented
        
        enum CodingKeys: String, CodingKey {
            case id
            case actionTaken = "action_taken"
        }
    }
}
