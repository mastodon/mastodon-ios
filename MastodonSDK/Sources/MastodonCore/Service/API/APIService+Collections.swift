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
            authorization: authorization,
            useBetaEndpoint: !authenticationBox.instanceSupportsNonBetaCollectionsAPI
        )
        
        return response
    }
    
    public func removeFromCollection(
        collectionId: Mastodon.Entity.Collection.ID,
        collectionMemberId: Mastodon.Entity.CollectionMember.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let authorization = authenticationBox.userAuthorization
        try await Mastodon.API.Collections.removeFromCollection(
            session: session,
            domain: authenticationBox.domain,
            collectionID: collectionId,
            itemID: collectionMemberId,
            authorization: authorization,
            useBetaEndpoint: !authenticationBox.instanceSupportsNonBetaCollectionsAPI
        )
        
        return
    }
}

fileprivate extension MastodonAuthenticationBox {
    @MainActor
    var instanceSupportsNonBetaCollectionsAPI: Bool {
        guard let isFeatureAvailable = authentication.instanceConfiguration?.isAvailable(.collections) else { return false }
        return isFeatureAvailable
    }
}
