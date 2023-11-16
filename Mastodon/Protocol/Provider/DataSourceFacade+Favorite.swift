//
//  DataSourceFacade+Favorite.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    public static func responseToStatusFavoriteAction(
        provider: DataSourceProvider & AuthContextProvider,
        status: Mastodon.Entity.Status
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
        
        _ = try await provider.context.apiService.favorite(
            record: status,
            authenticationBox: provider.authContext.mastodonAuthenticationBox
        )
    }
}
