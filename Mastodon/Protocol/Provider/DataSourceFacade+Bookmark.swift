//
//  DataSourceFacade+Bookmark.swift
//  Mastodon
//
//  Created by ProtoLimit on 2022/07/29.
//

import UIKit
import CoreData
import CoreDataStack
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    @MainActor
    public static func responseToStatusBookmarkAction(
        provider: NeedsDependency & AuthContextProvider & DataSourceProvider,
        status: MastodonStatus
    ) async throws {
        FeedbackGenerator.shared.generate(.selectionChanged)
        
        let updatedStatus = try await provider.context.apiService.bookmark(
            record: status,
            authenticationBox: provider.authContext.mastodonAuthenticationBox
        ).value
        
        let newStatus: MastodonStatus = .fromEntity(updatedStatus)
        newStatus.isSensitiveToggled = status.isSensitiveToggled
        
        provider.update(status: newStatus, intent: .bookmark(updatedStatus.bookmarked == true))
    }
}
