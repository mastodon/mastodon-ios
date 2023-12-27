//
//  DataSourceFacade+Block.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import CoreDataStack
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    static func responseToUserBlockAction(
        dependency: NeedsDependency & AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws -> Mastodon.Entity.Relationship {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        let apiService = dependency.context.apiService
        let authBox = dependency.authContext.mastodonAuthenticationBox

        let response = try await apiService.toggleBlock(
            account: account,
            authenticationBox: authBox
        )

        try await dependency.context.apiService.getBlocked(
            authenticationBox: authBox
        )

        dependency.context.authenticationService.fetchFollowingAndBlockedAsync()

        return response.value
    }
}
