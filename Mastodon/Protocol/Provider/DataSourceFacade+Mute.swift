//
//  DataSourceFacade+Mute.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-24.
//

import UIKit
import CoreDataStack
import MastodonCore

extension DataSourceFacade {
    static func responseToUserMuteAction(
        dependency: NeedsDependency & AuthContextProvider,
        user: ManagedObjectRecord<MastodonUser>
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
    
        _ = try await dependency.context.apiService.toggleMute(
            user: user,
            authenticationBox: dependency.authContext.mastodonAuthenticationBox
        )
    }   // end func
}
