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
    public enum ReplyPolicy: RawRepresentable, Codable {
        case followed
        case list
        case none
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "followed":        self = .followed
            case "list":            self = .list
            case "none":            self = .none
            default:                self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .followed:                 return "followed"
            case .list:                     return "list"
            case .none:                     return "none"
            case ._other(let value):        return value
            }
        }
    }
}
