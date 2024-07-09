// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore

extension DataSourceFacade {
    @MainActor
    static func coordinateToNotificationRequests(
        provider: DataSourceProvider & AuthContextProvider
    ) async {
        provider.coordinator.showLoading()

        do {
            let notificationRequests = try await provider.context.apiService.notificationRequests(authenticationBox: provider.authContext.mastodonAuthenticationBox)
            let viewModel = NotificationRequestsViewModel()

            provider.coordinator.hideLoading()

            provider.coordinator.present(scene: .notificationRequests(viewModel: viewModel), transition: .show)
        } catch {
            //TODO: Error Handling
            provider.coordinator.hideLoading()
        }
    }
}
