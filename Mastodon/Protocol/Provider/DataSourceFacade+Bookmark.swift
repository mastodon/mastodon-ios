//
//  DataSourceFacade+Bookmark.swift
//  Mastodon
//
//  Created by ProtoLimit on 2022/07/29.
//

import UIKit
import CoreData
import CoreDataStack

extension DataSourceFacade {
    static func responseToStatusBookmarkAction(
        dependency: NeedsDependency & UIViewController,
        status: ManagedObjectRecord<Status>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
        
        _ = try await dependency.context.apiService.bookmark(
            record: status,
            authenticationBox: authenticationBox
        )
    }
}
