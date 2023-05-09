// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonUI
import CoreDataStack
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    static func responseToUserViewButtonAction(
        dependency: NeedsDependency & AuthContextProvider,
        user: ManagedObjectRecord<MastodonUser>,
        buttonState: UserView.ButtonState
    ) async throws {
        switch buttonState {
        case .follow:
            try await DataSourceFacade.responseToUserFollowAction(
                dependency: dependency,
                user: user
            )
//            fetchFollowedBlockedUserIds(in: viewModel)
            if let userObject = user.object(in: dependency.context.managedObjectContext) {
                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followingUserIds.append(userObject.id)
            }
        case .unfollow:
            try await DataSourceFacade.responseToUserFollowAction(
                dependency: dependency,
                user: user
            )
            if let userObject = user.object(in: dependency.context.managedObjectContext) {
                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followingUserIds.removeAll(where: { $0 == userObject.id })
            }
        case .blocked:
            try await DataSourceFacade.responseToUserBlockAction(
                dependency: dependency,
                user: user
            )
//            fetchFollowedBlockedUserIds(in: viewModel)
            if let userObject = user.object(in: dependency.context.managedObjectContext) {
                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.blockedUserIds.append(userObject.id)
            }
        case .none, .loading:
            break //no-op
        }
    }
    
//    private static func fetchFollowedBlockedUserIds(in viewModel: FollowedBlockedUserIdProviding) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // hack: otherwise fetching the blocked users will not return the user followed
//            Task { @MainActor in
//                try await viewModel.fetchFollowedBlockedUserIds()
//            }
//        }
//    }
}
