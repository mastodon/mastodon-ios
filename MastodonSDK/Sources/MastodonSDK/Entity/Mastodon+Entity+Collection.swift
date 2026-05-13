//
//  Mastodon+Entity+Collection.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 4/29/26.
//

import Foundation

extension Mastodon.Entity {
    
    /// This is the response received when querying for all the collections belonging to an account
    public struct CollectionsList: Codable {
        public let collections: [Collection]
        public let partialAccounts: [PartialAccountWithAvatar]?
        
        enum CodingKeys: String, CodingKey {
            case collections
            case partialAccounts = "partial_accounts"
        }
    }
    
    /// Collection
    ///
    /// - Since: 4.6
    /// - Version: 4.6
    /// # Last Update
    ///   2026/04/29
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/) // not yet documented
    public struct Collection: Codable, Sendable {
        public typealias ID = String
        
        public let id: ID
        public let uri: String
        public let name: String?
        public let description: String?
        public let language: String?
        public let accountId: Mastodon.Entity.Account.ID
        public let local: Bool
        public let sensitive: Bool?
        public let discoverable: Bool?
        public let url: String
        public let itemCount: Int
        public let createdAt: Date
        public let updatedAt: Date?
        public let tag: Mastodon.Entity.Tag?
        public let items: [CollectionMember]
        
        enum CodingKeys: String, CodingKey {
            case id
            case uri
            case name
            case description
            case language
            case accountId = "account_id"
            case local
            case sensitive
            case discoverable
            case url
            case itemCount = "item_count"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case tag
            case items
        }
    }
    
    public struct CollectionMember: Codable, Sendable {
        public typealias ID = String
        public let id: ID
        public let state: String // needs an enum
        public let created_at: Date
        public let account_id: Mastodon.Entity.Account.ID?
    }
}

