// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK
import UIKit

extension DataSourceFacade {
    @MainActor
    static func coordinateToNotificationRequests(
        provider: DataSourceProvider & AuthContextProvider
    ) async {
        guard let sceneCoordinator = provider.sceneCoordinator else { return }
        sceneCoordinator.showLoading()

        do {
            let notificationRequests = try await APIService.shared.notificationRequests(authenticationBox: provider.authenticationBox).value
            let viewModel = NotificationRequestsViewModel(authenticationBox: provider.authenticationBox, requests: notificationRequests)

            sceneCoordinator.hideLoading()

            let transition: SceneCoordinator.Transition

            if provider.traitCollection.userInterfaceIdiom == .phone {
                transition = .show
            } else {
                transition = .modal(animated: true)
            }

            sceneCoordinator.present(scene: .notificationRequests(viewModel: viewModel), transition: transition)
        } catch {
            //TODO: Error Handling
            sceneCoordinator.hideLoading()
        }
    }



}
