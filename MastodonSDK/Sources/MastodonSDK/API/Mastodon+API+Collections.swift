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
#if true
        return Mastodon.API.endpointV1BetaURL(domain: domain).appendingPathComponent("collections") //  GET /api/v1_alpha/collections/:id
#else
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent(
            "collections")
#endif
    }
    
    internal static func accountCollectionsEndpointURL(
        domain: String,
        accountID: Mastodon.Entity.Account.ID
    ) -> URL {
#if true
        return Mastodon.API.endpointV1BetaURL(domain: domain).appendingPathComponent("accounts").appendingPathComponent(accountID).appendingPathComponent("collections")  // GET /api/v1_alpha/accounts/:account_id/collections
#else
       return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts").appendingPathComponent(accountID).appendingPathComponent("collections")
#endif
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
    ///   2026/04/29
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/) // not yet documented
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Mastodon.Entity.Collection]` nested in the response
    public static func getCollection(
        session: URLSession,
        domain: String,
        collectionID: Mastodon.Entity.Collection.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Collection> {
        let request = Mastodon.API.get(
            url: collectionsEndpointURL(domain: domain),
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("collection \(collectionID)")
        let (data, response) = try await session.data(for: request)
        let value = try Mastodon.API.decode(
            type: Mastodon.Entity.Collection.self, from: data,
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
}
