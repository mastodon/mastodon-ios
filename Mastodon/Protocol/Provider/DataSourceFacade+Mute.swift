//
//  DataSourceFacade+Mute.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import MastodonSDK
import MastodonCore

extension DataSourceFacade {
    static func responseToUserMuteAction(
        dependency: NeedsDependency & AuthContextProvider,
        account: Mastodon.Entity.Account
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
    
        _ = try await dependency.context.apiService.toggleMute(
            authenticationBox: dependency.authContext.mastodonAuthenticationBox,
            account: account
        )
    }   // end func
}
