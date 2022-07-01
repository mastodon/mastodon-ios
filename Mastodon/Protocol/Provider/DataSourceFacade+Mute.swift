//
//  DataSourceFacade+Mute.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import CoreDataStack

extension DataSourceFacade {
    static func responseToUserMuteAction(
        dependency: NeedsDependency,
        user: ManagedObjectRecord<MastodonUser>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
    
        _ = try await dependency.context.apiService.toggleMute(
            user: user,
            authenticationBox: authenticationBox
        )
    }   // end func
}
