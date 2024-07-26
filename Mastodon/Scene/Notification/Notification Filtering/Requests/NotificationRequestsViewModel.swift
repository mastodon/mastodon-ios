// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK
import MastodonCore

struct NotificationRequestsViewModel {
    let appContext: AppContext
    let authContext: AuthContext
    let coordinator: SceneCoordinator

    var requests: [Mastodon.Entity.NotificationRequest]

    init(appContext: AppContext, authContext: AuthContext, coordinator: SceneCoordinator, requests: [Mastodon.Entity.NotificationRequest]) {
        self.appContext = appContext
        self.authContext = authContext
        self.coordinator = coordinator
        self.requests = requests
    }
}
