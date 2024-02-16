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
            case .follow, .request, .unfollow, .blocked, .pending:
                _ = try await DataSourceFacade.responseToUserFollowAction(
                    dependency: dependency,
                    account: account
                )
            case .none, .loading:
                break //no-op
        }
    }
}
