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
        domain: String,
        useBetaEndpoint: Bool
    ) -> URL {
        if useBetaEndpoint {
            return Mastodon.API.endpointV1BetaURL(domain: domain).appendingPathComponent("collections") //  GET /api/v1_alpha/collections/:id
        } else {
            return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(
                "collections")
        }
    }
    
    internal static func accountCollectionsEndpointURL(
        domain: String,
        accountID: Mastodon.Entity.Account.ID,
        useBetaEndpoint: Bool
    ) -> URL {
        if useBetaEndpoint {
            return Mastodon.API.endpointV1BetaURL(domain: domain).appendingPathComponent("accounts").appendingPathComponent(accountID).appendingPathComponent("collections")  // GET /api/v1_alpha/accounts/:account_id/collections
        } else {
            return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts").appendingPathComponent(accountID).appendingPathComponent("collections")
        }
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
        authorization: Mastodon.API.OAuth.Authorization,
        useBetaEndpoint: Bool
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.CollectionsList> {
        let request = Mastodon.API.get(
            url: accountCollectionsEndpointURL(domain: domain, accountID: accountID, useBetaEndpoint: useBetaEndpoint),
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("collections list for account \(accountID)")
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.CollectionsList.self, from: data,
            response: response)
        
        return Mastodon.Response.Content(value: value, response: response)
    }
    
/*    /// Get a single collection
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
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Mastodon.Entity.Collection` nested in the response
 */
//    public static func getCollection(
//        session: URLSession,
//        domain: String,
//        collectionID: Mastodon.Entity.Collection.ID,
//        authorization: Mastodon.API.OAuth.Authorization,
//        useBetaEndpoint: Bool
//    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Collection> { // see the documentation - this does not simply return a collection, but an object with a "collection" entry and an "accounts" entry that contains a list of the accounts in the collection, as well as the owner of the collection
//        let request = Mastodon.API.get(
//            url: collectionsEndpointURL(domain: domain, useBetaEndpoint: useBetaEndpoint).appendingPathComponent(collectionID),
//            authorization: authorization
//        )
//        RateLimitViewModel.shared.didMakeRequest("collection \(collectionID)")
//        let (data, response) = try await session.data(for: request)
//        let value = try Mastodon.API.decode(
//            type: Mastodon.Entity.Collection.self, from: data,
//            response: response)
//        return Mastodon.Response.Content(value: value, response: response)
//    }
    
    public static func removeFromCollection(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        itemID: Mastodon.Entity.CollectionMember.ID,
        authorization: Mastodon.API.OAuth.Authorization,
        useBetaEndpoint: Bool
    ) async throws {
        let url = collectionsEndpointURL(domain: domain, useBetaEndpoint: useBetaEndpoint).appendingPathComponent(collectionID).appendingPathComponent("items").appendingPathComponent(itemID).appendingPathComponent("revoke")
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
        let request = Mastodon.API.post(url: collectionsEndpointURL(domain: domain, useBetaEndpoint: false), query: query, authorization: authorization)
        RateLimitViewModel.shared.didMakeRequest("create collection")
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(type: CollectionResponse.self, from: data, response: response)
        return Mastodon.Response.Content(value: value.collection, response: response)
    }
}
