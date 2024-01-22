//
//  Mastodon+API+Subscriptions+Policy.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-26.
//

import Foundation
import MastodonSDK
import MastodonAsset
import MastodonLocalization

extension Mastodon.API.Subscriptions.Policy {
    public var title: String {
        switch self {
            case .all:              return L10n.Scene.Settings.Notifications.Policy.anyone
            case .follower:         return L10n.Scene.Settings.Notifications.Policy.followers
            case .followed:         return L10n.Scene.Settings.Notifications.Policy.follow
            case .none, ._other:    return L10n.Scene.Settings.Notifications.Policy.noone
        }
    }
}
