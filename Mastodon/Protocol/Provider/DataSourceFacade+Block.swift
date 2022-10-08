//
//  DataSourceFacade+Block.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import CoreDataStack
import MastodonCore

extension DataSourceFacade {
    static func responseToUserBlockAction(
        dependency: NeedsDependency,
        user: ManagedObjectRecord<MastodonUser>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
    
        _ = try await dependency.context.apiService.toggleBlock(
            user: user,
            authenticationBox: authenticationBox
        )
    }   // end func
}
