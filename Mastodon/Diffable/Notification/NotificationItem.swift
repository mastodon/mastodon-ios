//
//  NotificationItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Foundation
import MastodonSDK

enum NotificationItem: Hashable {
    case feed(record: FeedNxt)
    case feedLoader(record: FeedNxt)
    case bottomLoader
}
