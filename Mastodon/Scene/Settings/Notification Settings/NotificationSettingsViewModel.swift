// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

class NotificationSettingsViewModel {

    var selectedPolicy: NotificationPolicy
    var notifyMentions: Bool
    var notifyBoosts: Bool
    var notifyFavorites: Bool
    var notifyNewFollowers: Bool

    var updated: Bool

    init(selectedPolicy: NotificationPolicy, notifyMentions: Bool, notifyBoosts: Bool, notifyFavorites: Bool, notifyNewFollowers: Bool) {
        self.selectedPolicy = selectedPolicy
        self.notifyMentions = notifyMentions
        self.notifyBoosts = notifyBoosts
        self.notifyFavorites = notifyFavorites
        self.notifyNewFollowers = notifyNewFollowers

        self.updated = false
    }
}
