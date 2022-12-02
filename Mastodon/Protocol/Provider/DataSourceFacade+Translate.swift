//
//  DataSourceFacade+Translate.swift
//  Mastodon
//
//  Created by Marcus Kida on 29.11.22.
//

import UIKit
import CoreData
import CoreDataStack
import MastodonCore

extension DataSourceFacade {
    public static func translateStatus(
        provider: UIViewController & NeedsDependency & AuthContextProvider,
        status: ManagedObjectRecord<Status>
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()

        guard
            let status = status.object(in: provider.context.managedObjectContext)
        else {
            return
        }
        
        let result = try await provider.context
            .apiService
            .translateStatus(
                statusID: status.id,
                authenticationBox: provider.authContext.mastodonAuthenticationBox
            ).value
        
        status.translatedContent = result.content
    }
}
