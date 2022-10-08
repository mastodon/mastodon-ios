//
//  DataSourceFacade+Reblog.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import CoreDataStack
import MastodonCore
import MastodonUI

extension DataSourceFacade {
    static func responseToStatusReblogAction(
        provider: DataSourceProvider,
        status: ManagedObjectRecord<Status>,
        authenticationBox: MastodonAuthenticationBox
    ) async throws {
        let selectionFeedbackGenerator = await UISelectionFeedbackGenerator()
        await selectionFeedbackGenerator.selectionChanged()
        
        _ = try await provider.context.apiService.reblog(
            record: status,
            authenticationBox: authenticationBox
        )
    }   // end func
}
