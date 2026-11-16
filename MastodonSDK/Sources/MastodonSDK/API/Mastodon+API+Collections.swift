//
//  Mastodon+API+Collections.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 4/29/26.
//
import Combine
import Foundation

extension Mastodon.API.Collections {
    internal static func collectionsEndpointURL(
        domain: String
    ) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(
            "collections")
    }
    
    internal static func accountCollectionsEndpointURL(
        domain: String,
        accountID: Mastodon.Entity.Account.ID
    ) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts").appendingPathComponent(accountID).appendingPathComponent("collections")
    }
    
    /// Get all collections created by an account
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///   2026/04/29
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/) // not yet documented
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountID: account id that would have created the collections
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Mastodon.Entity.Collection]` nested in the response
    public static func getCollectionsFromAccount(
        session: URLSession,
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.CollectionsList> {
        let request = Mastodon.API.get(
            url: accountCollectionsEndpointURL(domain: domain, accountID: accountID),
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("collections list for account \(accountID)")
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.CollectionsList.self, from: data,
            response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    /// Get a single collection
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///   2026/11/16
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/collections/#get_collection)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - collectionID: the id of the collection to fetch
    ///   - authorization: User token
    /// - Returns: `Mastodon.Entity.CollectionWithAccounts` wrapped in the Response
    public static func getCollection(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.CollectionWithAccounts> {
        let request = Mastodon.API.get(
            url: collectionsEndpointURL(domain: domain).appendingPathComponent(collectionID),
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("collection \(collectionID)")
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.CollectionWithAccounts.self, from: data,
            response: response)
        return Mastodon.Response.Content(value: value, response: response)
    }
    
    public static func removeFromCollection(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        itemID: Mastodon.Entity.CollectionMember.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws {
        let url = collectionsEndpointURL(domain: domain).appendingPathComponent(collectionID).appendingPathComponent("items").appendingPathComponent(itemID).appendingPathComponent("revoke")
        let request = Mastodon.API.post(url: url,
                                          query: nil,
                                          authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("remove \(itemID) from collection \(collectionID)")
        let (data, response) = try await session.data(for: request)
        try Mastodon.API.decodeEmpty(from: data, response: response)
        return
    }
    
    public struct CreateCollectionQuery: Codable, PostQuery {
        public let name: String
        public let description: String?
        public let language: String?
        public let tagName: String?
        public let sensitive: Bool
        public let discoverable: Bool
        public let accountIDs: [Mastodon.Entity.Account.ID]
        
        enum CodingKeys: String, CodingKey {
            case name
            case description
            case language
            case tagName = "tag_name"
            case sensitive
            case discoverable
            case accountIDs = "account_ids"
        }
        
        public init(
            name: String,
            description: String?,
            language: String?,
            tagName: String?,
            sensitive: Bool,
            discoverable: Bool,
            accountIDs: [Mastodon.Entity.Account.ID]
        ) {
            self.name = name
            self.description = description
            self.language = language
            self.tagName = tagName
            self.sensitive = sensitive
            self.discoverable = discoverable
            self.accountIDs = accountIDs
        }
    }
    
    private struct CollectionResponse: Decodable {
        let collection: Mastodon.Entity.Collection
    }
    
    /// Create a collection
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///  2026/11/12
    /// # [Document](https://docs.joinmastodon.org/methods/collections/#create)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain
    ///   - query: the new collection's details and the accounts to feature
    ///   - authorization: User token
    /// - Returns: the new `Mastodon.Entity.Collection`, unwrapped from the response
    public static func createCollection(
        session: URLSession,
        domain: String,
        query: CreateCollectionQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Collection> {
        let request = Mastodon.API.post(url: collectionsEndpointURL(domain: domain), query: query, authorization: authorization)
        RateLimitViewModel.shared.didMakeRequest("create collection")
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(type: CollectionResponse.self, from: data, response: response)
        return Mastodon.Response.Content(value: value.collection, response: response)
    }
    
    public struct UpdateCollectionQuery: Encodable, PatchQuery {
        public let name: String
        public let description: String?
        public let language: String?
        public let tagName: String?
        public let sensitive: Bool
        public let discoverable: Bool
        
        enum CodingKeys: String, CodingKey {
            case name
            case description
            case language
            case tagName = "tag_name"
            case sensitive
            case discoverable
        }
        
        public init(
            name: String,
            description: String?,
            language: String?,
            tagName: String?,
            sensitive: Bool,
            discoverable: Bool
        ) {
            self.name = name
            self.description = description
            self.language = language
            self.tagName = tagName
            self.sensitive = sensitive
            self.discoverable = discoverable
        }
        
        // required in order to send `null` for empty fields, which clears them on the server
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(name, forKey: .name)
            try container.encode(description, forKey: .description)
            try container.encode(language, forKey: .language)
            try container.encode(tagName, forKey: .tagName)
            try container.encode(sensitive, forKey: .sensitive)
            try container.encode(discoverable, forKey: .discoverable)
        }
    }
    
    /// Update a collection's details
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///  2026/11/16
    /// # [Document](https://docs.joinmastodon.org/methods/collections/#update_collection)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain
    ///   - collectionID: the collection to update
    ///   - query: the collection's updated details
    ///   - authorization: User token
    /// - Returns: the updated `Mastodon.Entity.Collection`, unwrapped from the response
    public static func updateCollection(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        query: UpdateCollectionQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Collection> {
        let url = collectionsEndpointURL(domain: domain).appendingPathComponent(collectionID)
        let request = Mastodon.API.patch(url: url, query: query, authorization: authorization)
        
        RateLimitViewModel.shared.didMakeRequest("update collection \(collectionID)")
        
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(type: CollectionResponse.self, from: data, response: response)
        return Mastodon.Response.Content(value: value.collection, response: response)
    }
    
    private struct AddCollectionItemQuery: Encodable, PostQuery {
        let accountID: Mastodon.Entity.Account.ID
        
        enum CodingKeys: String, CodingKey {
            case accountID = "account_id"
        }
    }
    
    private struct CollectionItemResponse: Decodable {
        let collectionItem: Mastodon.Entity.CollectionMember
        
        enum CodingKeys: String, CodingKey {
            case collectionItem = "collection_item"
        }
    }
    
    /// Add an item to a collection
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///  2026/11/16
    /// # [Document](https://docs.joinmastodon.org/methods/collections/#add_account)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain
    ///   - collectionID: the collection to add to
    ///   - accountID: the account to add
    ///   - authorization: User token
    /// - Returns: the new item, which has an `id` that can be used to delete the item
    public static func addAccountToCollection(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        accountID: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.CollectionMember> {
        let url = collectionsEndpointURL(domain: domain).appendingPathComponent(collectionID).appendingPathComponent("items")
        let request = Mastodon.API.post(url: url, query: AddCollectionItemQuery(accountID: accountID), authorization: authorization)
        
        RateLimitViewModel.shared.didMakeRequest("add account \(accountID) to collection \(collectionID)")
        
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(type: CollectionItemResponse.self, from: data, response: response)
        return Mastodon.Response.Content(value: value.collectionItem, response: response)
    }
    
    /// Remove an item from a collection
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///  2026/11/16
    /// # [Document](https://docs.joinmastodon.org/methods/collections/#remove_account)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain
    ///   - collectionID: the collection to remove from
    ///   - itemID: the id of the item to remove
    ///   - authorization: User token
    public static func deleteCollectionItem(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        itemID: Mastodon.Entity.CollectionMember.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws {
        let url = collectionsEndpointURL(domain: domain).appendingPathComponent(collectionID).appendingPathComponent("items").appendingPathComponent(itemID)
        let request = Mastodon.API.delete(url: url, query: nil, authorization: authorization)
        
        RateLimitViewModel.shared.didMakeRequest("delete item \(itemID) from collection \(collectionID)")
        
        let (data, response) = try await session.data(for: request)
        try Mastodon.API.decodeEmpty(from: data, response: response)
    }

    /// Delete a collection
    ///
    /// - Since: 4.6.0
    /// - Version: 4.6.0
    /// # Last Update
    ///  2026/11/18
    /// # [Document](https://docs.joinmastodon.org/methods/collections/#delete_collection)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain
    ///   - collectionID: the collection to delete
    ///   - authorization: User token
    public static func deleteCollection(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws {
        let url = collectionsEndpointURL(domain: domain).appendingPathComponent(collectionID)
        let request = Mastodon.API.delete(url: url, query: nil, authorization: authorization)
        
        RateLimitViewModel.shared.didMakeRequest("delete collection \(collectionID)")
        
        let (data, response) = try await session.data(for: request)
        try Mastodon.API.decodeEmpty(from: data, response: response)
    }
}
