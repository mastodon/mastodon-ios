// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Combine
import MastodonCore

protocol FollowedBlockedUserIdProviding {
    var context: AppContext { get }
    var authContext: AuthContext { get }
        
    var followedUserIds: CurrentValueSubject<[String], Never> { get }
    var blockedUserIds: CurrentValueSubject<[String], Never> { get }
}

extension FollowedBlockedUserIdProviding {
    func fetchFollowedBlockedUserIds() async throws {
        let followingIds = try await context.apiService.following(
            userID: authContext.mastodonAuthenticationBox.userID,
            maxID: nil,
            authenticationBox: authContext.mastodonAuthenticationBox
        ).value.map { $0.id }

        let blockedIds = try await context.apiService.getBlocked(
            authenticationBox: authContext.mastodonAuthenticationBox
        ).value.map { $0.id }
        
        Task { @MainActor in
            followedUserIds.send(followingIds)
            blockedUserIds.send(blockedIds)
        }
    }
}
