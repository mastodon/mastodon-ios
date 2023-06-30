// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonLocalization

struct NotificationSettingsSection: Hashable {
    let entries: [NotificationSettingEntry]
}

enum NotificationSettingEntry: Hashable {
    case policy
    case alert(NotificationAlert)
}

enum NotificationPolicy: Hashable {
    case anyone
    case followers
    case follow
    case noone

    var title: String {
        switch self {
        case .anyone:
            return L10n.Scene.Settings.Notifications.Policy.anyone
        case .followers:
            return L10n.Scene.Settings.Notifications.Policy.followers
        case .follow:
            return L10n.Scene.Settings.Notifications.Policy.follow
        case .noone:
            return L10n.Scene.Settings.Notifications.Policy.noone
        }
    }
}

enum NotificationAlert: Hashable, CaseIterable {
    case mentionsAndReplies
    case boosts
    case favorites
    case newFollowers

    var title: String {
        switch self {

        case .mentionsAndReplies:
            return L10n.Scene.Settings.Notifications.Alert.mentionsAndReplies
        case .boosts:
            return L10n.Scene.Settings.Notifications.Alert.boosts
        case .favorites:
            return L10n.Scene.Settings.Notifications.Alert.favorites
        case .newFollowers:
            return L10n.Scene.Settings.Notifications.Alert.newFollowers
        }
    }
}
