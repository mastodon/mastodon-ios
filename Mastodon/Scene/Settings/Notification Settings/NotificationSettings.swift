// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonLocalization
import MastodonSDK
import CoreDataStack

struct NotificationSettingsSection: Hashable {
    let entries: [NotificationSettingEntry]
}

enum NotificationSettingEntry: Hashable {
    case notificationDisabled
    case policy
    case alert(NotificationAlert)
}

struct NotificationPolicySection: Hashable {
    let entries: [NotificationPolicy]
}

enum NotificationPolicy: Hashable, CaseIterable {
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

    var subscriptionPolicy: Mastodon.API.Subscriptions.Policy {
        switch self {
            case .anyone:
                return .all
            case .followers:
                return .follower
            case .follow:
                return .followed
            case .noone:
                return .none
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

extension Subscription {
    var notificationPolicy: NotificationPolicy? {
        guard let policy else { return nil }

        switch policy {
            case .all:
                return .anyone
            case .followed:
                return .follow
            case .follower:
                return .followers
            case .none:
                return .noone
            case ._other(_):
                return .noone
        }
    }
}
