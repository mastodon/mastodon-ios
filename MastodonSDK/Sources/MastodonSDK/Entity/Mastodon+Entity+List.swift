//
//  Mastodon+Entity+List.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    /// List
    ///
    /// - Since: 2.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/28
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/list/)
    public struct List: Codable {
        public typealias ID = String
        
        public let id: ID
        public let title: String
        public let repliesPolicy: ReplyPolicy?
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case repliesPolicy = "replies_policy"
        }
    }
}

extension Mastodon.Entity {
    public enum ReplyPolicy: String, Codable {
        case followed
        case list
        case none
    }
}
