//
//  APIService+FollowRequest.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/27.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService {
    
    public func followRequest(
        userID: Mastodon.Entity.Account.ID,
        query: Mastodon.API.Account.FollowRequestQuery,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.Relationship> {
        let response = try await Mastodon.API.Account.followRequest(
            session: session,
            domain: authenticationBox.domain,
            userID: userID,
            query: query,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()
        
        return response
    }

    public func pendingFollowRequest(
        userID: Mastodon.Entity.Account.ID,
        authenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Response.Content<[Mastodon.Entity.Account]> {
        let response = try await Mastodon.API.Account.pendingFollowRequest(
            session: session,
            domain: authenticationBox.domain,
            userID: userID,
            authorization: authenticationBox.userAuthorization
        ).singleOutput()

        return response
    }
}
