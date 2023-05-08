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
        buttonState: UserView.ButtonState,
        viewModel: FollowedBlockedUserIdProviding
    ) async throws {
        switch buttonState {
        case .follow, .unfollow:
            try await DataSourceFacade.responseToUserFollowAction(
                dependency: dependency,
                user: user
            )
            fetchFollowedBlockedUserIds(in: viewModel)
        case .blocked:
            try await DataSourceFacade.responseToUserBlockAction(
                dependency: dependency,
                user: user
            )
            fetchFollowedBlockedUserIds(in: viewModel)
        case .none, .loading:
            break //no-op
        }
    }
    
    private static func fetchFollowedBlockedUserIds(in viewModel: FollowedBlockedUserIdProviding) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // hack: otherwise fetching the blocked users will not return the user followed
            Task { @MainActor in
                try await viewModel.fetchFollowedBlockedUserIds()
            }
        }
    }
}
