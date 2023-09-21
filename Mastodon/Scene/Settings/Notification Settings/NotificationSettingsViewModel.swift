// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

class NotificationSettingsViewModel {
    var selectedPolicy: NotificationPolicy

    init(selectedPolicy: NotificationPolicy) {
        self.selectedPolicy = selectedPolicy
    }
}
