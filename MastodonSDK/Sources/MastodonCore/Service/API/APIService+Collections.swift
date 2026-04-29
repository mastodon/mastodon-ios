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
}
