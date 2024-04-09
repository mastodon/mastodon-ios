//
//  DataSourceFacade+Reblog.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import MastodonCore
import MastodonUI
import MastodonSDK
import MastodonLocalization

extension DataSourceFacade {
    @MainActor
    static func responseToStatusReblogAction(
        provider: DataSourceProvider & AuthContextProvider,
        status: MastodonStatus
    ) async throws {
        if UserDefaults.shared.askBeforeBoostingAPost {
            let alertController = UIAlertController(
                title: status.entity.reblogged == true ? L10n.Common.Alerts.BoostAPost.titleUnboost : L10n.Common.Alerts.BoostAPost.titleBoost,
                message: nil,
                preferredStyle: .alert
            )
            let cancelAction = UIAlertAction(title: L10n.Common.Alerts.BoostAPost.cancel, style: .default)
            alertController.addAction(cancelAction)
            let confirmAction = UIAlertAction(
                title: status.entity.reblogged == true ? L10n.Common.Alerts.BoostAPost.unboost : L10n.Common.Alerts.BoostAPost.boost,
                style: .default
            ) { _ in
                Task { @MainActor in
                    try? await performReblog(provider: provider, status: status)
                }
            }
            alertController.addAction(confirmAction)
            provider.present(alertController, animated: true)
        } else {
            try await performReblog(provider: provider, status: status)
        }
    }
}

private extension DataSourceFacade {
    @MainActor
    static func performReblog(
        provider: DataSourceProvider & AuthContextProvider,
        status: MastodonStatus
    ) async throws {
        FeedbackGenerator.shared.generate(.selectionChanged)

        let updatedStatus = try await provider.context.apiService.reblog(
            status: status,
            authenticationBox: provider.authContext.mastodonAuthenticationBox
        ).value

        let newStatus: MastodonStatus = .fromEntity(updatedStatus)
        newStatus.reblog?.isSensitiveToggled = status.isSensitiveToggled
        newStatus.isSensitiveToggled = status.isSensitiveToggled
        
        provider.update(status: newStatus, intent: .reblog(updatedStatus.reblogged == true))
    }
}
