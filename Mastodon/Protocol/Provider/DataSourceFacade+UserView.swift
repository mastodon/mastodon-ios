// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonUI
import CoreDataStack
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    static func responseToUserViewButtonAction(
        dependency: NeedsDependency & AuthContextProvider,
        account: Mastodon.Entity.Account,
        buttonState: UserView.ButtonState
    ) async throws {
        switch buttonState {
            case .follow:
                _ = try await DataSourceFacade.responseToUserFollowAction(
                    dependency: dependency,
                    account: account
                )

                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followingUserIds.append(account.id)
            case .request:
                _ = try  await DataSourceFacade.responseToUserFollowAction(
                    dependency: dependency,
                    account: account
                )

                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followRequestedUserIDs.append(account.id)
            case .unfollow:
                _ = try  await DataSourceFacade.responseToUserFollowAction(
                    dependency: dependency,
                    account: account
                )

                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followingUserIds.removeAll(where: { $0 == account.id })
            case .blocked:
                try  await DataSourceFacade.responseToUserBlockAction(
                    dependency: dependency,
                    account: account
                )

                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.blockedUserIds.append(account.id)

            case .pending:
                _ = try  await DataSourceFacade.responseToUserFollowAction(
                    dependency: dependency,
                    account: account
                )

                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followRequestedUserIDs.removeAll(where: { $0 == account.id })
            case .none, .loading:
                break //no-op
        }
    }
}
