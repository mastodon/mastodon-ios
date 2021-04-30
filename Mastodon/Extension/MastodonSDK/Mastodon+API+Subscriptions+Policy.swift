//
//  Mastodon+API+Subscriptions+Policy.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-26.
//

import Foundation
import MastodonSDK

extension Mastodon.API.Subscriptions.Policy {
    var title: String {
        switch self {
        case .all:              return L10n.Scene.Settings.Section.Notifications.Trigger.anyone
        case .follower:         return L10n.Scene.Settings.Section.Notifications.Trigger.follower
        case .followed:         return L10n.Scene.Settings.Section.Notifications.Trigger.follow
        case .none, ._other:    return L10n.Scene.Settings.Section.Notifications.Trigger.noone
        }
    }
}
