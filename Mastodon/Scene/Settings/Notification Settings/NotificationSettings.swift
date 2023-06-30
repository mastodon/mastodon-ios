// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

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
            return "Anyone"
        case .followers:
            return "People who follow you"
        case .follow:
            return "People you follow"
        case .noone:
            return "No one"
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
            return "Mentions & Replies"
        case .boosts:
            return "Boosts"
        case .favorites:
            return "Favorites"
        case .newFollowers:
            return "New Followers"
        }
    }
}
