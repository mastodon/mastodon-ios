//
//  NotificationType.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-7-3.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonNotification {
    var notificationType: Mastodon.Entity.Notification.NotificationType {
        return Mastodon.Entity.Notification.NotificationType(rawValue: typeRaw) ?? ._other(typeRaw)
    }
}
