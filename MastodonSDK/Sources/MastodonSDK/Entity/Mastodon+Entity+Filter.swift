//
//  Mastodon+Entity+Filter.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/28.
//

import Foundation

extension Mastodon.Entity {
    
    
    public enum FilterAction: RawRepresentable, Codable, Sendable {
        public typealias RawValue = String
        case warn
        case hide
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "warn": self = .warn
            case "hide": self = .hide
            default: self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .warn: return "warn"
            case .hide: return "hide"
            case ._other(let value): return value
            }
        }
    }
    
    
    
    /// Filter
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.0
    /// # Last Update
    ///   2024/11/25
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/filter/)
    public struct FilterV2: Codable, Sendable {
        
        public struct FilterKeyword: Codable, Sendable {
            let id: String
            let keyword: String
            let wholeWord: Bool
            
            enum CodingKeys: String, CodingKey {
                case id
                case keyword
                case wholeWord = "whole_word"
            }
        }
        
        public typealias ID = String
        
        public let id: ID
        public let title: String
        public let context: [FilterContext]
        public let expiresAt: Date?
        public let filterAction: FilterAction
        public let keywords: [FilterKeyword]?
//        public let statuses  // not using this for now
        
        enum CodingKeys: String, CodingKey {
            case id
            case title
            case context
            case expiresAt = "expires_at"
            case filterAction = "filter_action"
            case keywords
        }
        
        
    }

}

extension Mastodon.Entity {
    public enum FilterContext: RawRepresentable, Codable, Hashable, Sendable {
        case home
        case notifications
        case `public`
        case thread
        case account
        
        case _other(String)
        
        public init?(rawValue: String) {
            switch rawValue {
            case "home":                self = .home
            case "notifications":       self = .notifications
            case "public":              self = .`public`
            case "thread":              self = .thread
            case "account":             self = .account
            default:                    self = ._other(rawValue)
            }
        }
        
        public var rawValue: String {
            switch self {
            case .home:                     return "home"
            case .notifications:            return "notifications"
            case .public:                   return "public"
            case .thread:                   return "thread"
            case .account:                  return "account"
            case ._other(let value):        return value
            }
        }
    }
}
