//
//  NotificationItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import Foundation
import MastodonSDK

enum NotificationItem: Hashable {
    case filteredNotifications(policy: Mastodon.Entity.NotificationPolicy)
    case feed(record: MastodonFeed)
    case feedLoader(record: MastodonFeed)
    case bottomLoader
}
