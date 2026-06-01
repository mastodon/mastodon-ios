//
//  APIService+Follow.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-2.
//

import UIKit
import Combine
import MastodonSDK

extension APIService {

    private struct MastodonFollowContext {
        let sourceUserID: String
        let targetUserID: String
        let isFollowing: Bool
        let isPending: Bool
        let needsUnfollow: Bool
    }
    public func follow(_ accountID: String, hideBoosts: Bool = false, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        return try await Mastodon.API.Account.follow(
            session: session,
            domain: authenticationBox.domain,
            accountID: accountID,
            followQueryType: .follow(query: .init(reblogs: !hideBoosts)),
            authorization: authenticationBox.userAuthorization
        ).singleOutput().value
    }
    
    public func unfollow(_ accountID: String, authenticationBox: MastodonAuthenticationBox) async throws -> Mastodon.Entity.Relationship {
        return try await Mastodon.API.Account.unfollow(
            session: session,
            domain: authenticationBox.domain,
            accountID: accountID,
            authorization: authenticationBox.userAuthorization
        ).singleOutput().value
    }

}
