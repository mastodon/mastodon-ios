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
        user: ManagedObjectRecord<MastodonUser>
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        let apiService = dependency.context.apiService
        let authBox = dependency.authContext.mastodonAuthenticationBox
        
        _ = try await apiService.toggleBlock(
            user: user,
            authenticationBox: authBox
        )
        
        try await dependency.context.apiService.getBlocked(
            authenticationBox: authBox
        )
        dependency.context.authenticationService.fetchFollowingAndBlockedAsync()
    }

    static func responseToUserBlockAction(
        dependency: NeedsDependency & AuthContextProvider,
        user: Mastodon.Entity.Account
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        let apiService = dependency.context.apiService
        let authBox = dependency.authContext.mastodonAuthenticationBox

        _ = try await apiService.toggleBlock(
            user: user,
            authenticationBox: authBox
        )

        try await dependency.context.apiService.getBlocked(
            authenticationBox: authBox
        )
        dependency.context.authenticationService.fetchFollowingAndBlockedAsync()
    }

    static func responseToDomainBlockAction(
        dependency: NeedsDependency & AuthContextProvider,
        user: ManagedObjectRecord<MastodonUser>
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        let apiService = dependency.context.apiService
        let authBox = dependency.authContext.mastodonAuthenticationBox

        _ = try await apiService.toggleDomainBlock(user: user, authenticationBox: authBox)
    }
}
