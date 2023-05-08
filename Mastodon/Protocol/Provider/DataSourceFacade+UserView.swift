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
        case .follow, .unfollow:
            try await DataSourceFacade.responseToUserFollowAction(
                dependency: dependency,
                user: user
            )
        case .blocked:
            try await DataSourceFacade.responseToUserBlockAction(
                dependency: dependency,
                user: user
            )
        case .none, .loading:
            break //no-op
        }
    }
}
