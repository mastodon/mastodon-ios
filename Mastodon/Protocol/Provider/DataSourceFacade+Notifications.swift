// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

extension DataSourceFacade {
    @MainActor
    static func coordinateToNotificationRequests(
        provider: DataSourceProvider & AuthContextProvider
    ) async {
        provider.coordinator.showLoading()

        do {
            let notificationRequests = try await provider.context.apiService.notificationRequests(authenticationBox: provider.authContext.mastodonAuthenticationBox).value
            let viewModel = NotificationRequestsViewModel(appContext: provider.context, authContext: provider.authContext, coordinator: provider.coordinator, requests: notificationRequests)

            provider.coordinator.hideLoading()

            provider.coordinator.present(scene: .notificationRequests(viewModel: viewModel), transition: .show)
        } catch {
            //TODO: Error Handling
            provider.coordinator.hideLoading()
        }
    }

    @MainActor
    static func coordinateToNotificationRequest(
        request: Mastodon.Entity.NotificationRequest,
        provider: ViewControllerWithDependencies & AuthContextProvider
    ) async {
        provider.coordinator.showLoading()

        let notificationTimelineViewModel = NotificationTimelineViewModel(context: provider.context, authContext: provider.authContext, scope: .fromAccount(request.account))

        provider.coordinator.hideLoading()
        provider.coordinator.present(scene: .notificationTimeline(viewModel: notificationTimelineViewModel), transition: .show)
    }

}
