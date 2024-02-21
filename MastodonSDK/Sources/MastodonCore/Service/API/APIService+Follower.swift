//
//  APIService+Follower.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    public func followers(
        userID: Mastodon.Entity.Account.ID,
        maxID: String?,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let domain = authenticationBox.domain
        let authorization = authenticationBox.userAuthorization
        
        let query = Mastodon.API.Account.FollowerQuery(
            maxID: maxID,
            limit: nil
        )
        let response = try await Mastodon.API.Account.followers(
            session: session,
            domain: domain,
            userID: userID,
            query: query,
            authorization: authorization
        ).singleOutput()

        return response
    }
}
