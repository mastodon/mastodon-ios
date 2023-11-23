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
        status: MastodonStatus
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
        
        let newStatus = try await provider.context.apiService.reblog(
            status: status,
            authenticationBox: provider.authContext.mastodonAuthenticationBox
        ).value

        provider.update(status: .fromEntity(newStatus))
    }
}
