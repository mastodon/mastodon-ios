//
//  DataSourceFacade+Favorite.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import CoreData
import MastodonSDK
import MastodonCore

extension DataSourceFacade {
    @MainActor
    public static func responseToStatusFavoriteAction(
        provider: DataSourceProvider & AuthContextProvider,
        status: MastodonStatus
    ) async throws {
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.selectionChanged()
        
        let updatedStatus = try await provider.context.apiService.favorite(
            status: status,
            authenticationBox: provider.authContext.mastodonAuthenticationBox
        ).value
        
        let newStatus: MastodonStatus = .fromEntity(updatedStatus)
        newStatus.isSensitiveToggled = status.isSensitiveToggled
        
        provider.update(status: newStatus, intent: .favorite(updatedStatus.favourited == true))
    }
}
