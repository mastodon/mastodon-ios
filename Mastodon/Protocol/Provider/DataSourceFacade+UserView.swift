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

            if let userObject = user.object(in: dependency.context.managedObjectContext) {
                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followingUserIds.append(userObject.id)
            }

        case .request:
            try await DataSourceFacade.responseToUserFollowAction(
                dependency: dependency,
                user: user
            )

            if let userObject = user.object(in: dependency.context.managedObjectContext) {
                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followRequestedUserIDs.append(userObject.id)
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

            if let userObject = user.object(in: dependency.context.managedObjectContext) {
                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.blockedUserIds.append(userObject.id)
            }
            
        case .pending:
            try await DataSourceFacade.responseToUserFollowAction(
                dependency: dependency,
                user: user
            )

            if let userObject = user.object(in: dependency.context.managedObjectContext) {
                dependency.authContext.mastodonAuthenticationBox.inMemoryCache.followRequestedUserIDs.removeAll(where: { $0 == userObject.id })
            }
        case .none, .loading:
            break //no-op
        }
    }
}

extension UserTableViewCellDelegate where Self: NeedsDependency & AuthContextProvider {
    func userView(_ view: UserView, didTapButtonWith state: UserView.ButtonState, for user: MastodonUser) {
        Task {
            try await DataSourceFacade.responseToUserViewButtonAction(
                dependency: self,
                user: user.asRecord,
                buttonState: state
            )
        }
    }
}
