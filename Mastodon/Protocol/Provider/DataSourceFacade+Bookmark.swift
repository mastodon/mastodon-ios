//
//  DataSourceFacade+Bookmark.swift
//  Mastodon
//
//  Created by ProtoLimit on 2022/07/29.
//

import UIKit
import MastodonSDK
import MastodonCore

extension DataSourceFacade {
    public static func responseToStatusBookmarkAction(
        provider: UIViewController & NeedsDependency & AuthContextProvider,
        status: Mastodon.Entity.Status
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
        
        _ = try await provider.context.apiService.bookmark(
            record: status,
            authenticationBox: provider.authContext.mastodonAuthenticationBox
        )
    }
}
