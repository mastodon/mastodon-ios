// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK
import MastodonCore

struct NotificationRequestsViewModel {
    let authenticationBox: MastodonAuthenticationBox

    var requests: [Mastodon.Entity.NotificationRequest]

    init(authenticationBox: MastodonAuthenticationBox, requests: [Mastodon.Entity.NotificationRequest]) {
        self.authenticationBox = authenticationBox
        self.requests = requests
    }
}
