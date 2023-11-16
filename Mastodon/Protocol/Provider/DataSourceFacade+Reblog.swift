//
//  DataSourceFacade+Reblog.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import MastodonCore
import MastodonUI
import MastodonSDK

extension DataSourceFacade {
    static func responseToStatusReblogAction(
        provider: DataSourceProvider & AuthContextProvider,
        status: Mastodon.Entity.Status
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
        
        _ = try await provider.context.apiService.reblog(
            record: status,
            authenticationBox: provider.authContext.mastodonAuthenticationBox
        )
    }   // end func
}
