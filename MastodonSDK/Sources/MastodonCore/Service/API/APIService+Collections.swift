//
//  APIService+Collections.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 4/29/26.
//

import MastodonSDK

extension APIService {
    
    public func collections(
        accountID: Mastodon.Entity.Account.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.CollectionsList> {
        let authorization = authenticationBox.userAuthorization
        let response = try await Mastodon.API.Collections.getCollectionsFromAccount(
            session: session,
            domain: authenticationBox.domain,
            accountID: accountID,
            authorization: authorization
        )
        
        return response
    }
    
    public func removeFromCollection(
        collectionID: Mastodon.Entity.Collection.ID,
        collectionMemberID: Mastodon.Entity.CollectionMember.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let authorization = authenticationBox.userAuthorization
        try await Mastodon.API.Collections.removeFromCollection(
            session: session,
            domain: authenticationBox.domain,
            collectionID: collectionID,
            itemID: collectionMemberID,
            authorization: authorization
        )
    }
    
    public func createCollection(
        _ query: Mastodon.API.Collections.CreateCollectionQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Collection> {
        let authorization = authenticationBox.userAuthorization
        let response = try await Mastodon.API.Collections.createCollection(session: session,
                                                                           domain: authenticationBox.domain,
                                                                           query: query,
                                                                           authorization: authorization)
        return response
    }
    
    public func collection(
        id: Mastodon.Entity.Collection.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.CollectionWithAccounts> {
        try await Mastodon.API.Collections.getCollection(session: session, domain: authenticationBox.domain, collectionID: id, authorization: authenticationBox.userAuthorization)
    }
    
    public func updateCollection(
        collectionID: Mastodon.Entity.Collection.ID,
        query: Mastodon.API.Collections.UpdateCollectionQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Collection> {
        try await Mastodon.API.Collections.updateCollection(session: session, domain: authenticationBox.domain, collectionID: collectionID, query: query, authorization: authenticationBox.userAuthorization)
    }
    
    public func addAccountToCollection(
        collectionID: Mastodon.Entity.Collection.ID,
        accountID: Mastodon.Entity.Account.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.CollectionMember> {
        try await Mastodon.API.Collections.addAccountToCollection(session: session, domain: authenticationBox.domain, collectionID: collectionID, accountID: accountID, authorization: authenticationBox.userAuthorization)
    }
    
    public func deleteCollectionItem(
        collectionID: Mastodon.Entity.Collection.ID,
        itemID: Mastodon.Entity.CollectionMember.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        try await Mastodon.API.Collections.deleteCollectionItem(session: session, domain: authenticationBox.domain, collectionID: collectionID, itemID: itemID, authorization: authenticationBox.userAuthorization)
    }
    
    public func deleteCollection(
        collectionID: Mastodon.Entity.Collection.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        try await Mastodon.API.Collections.deleteCollection(session: session, domain: authenticationBox.domain, collectionID: collectionID, authorization: authenticationBox.userAuthorization)
    }
}
