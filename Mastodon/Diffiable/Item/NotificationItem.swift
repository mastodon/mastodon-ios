//
//  NotificationItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import Foundation

enum NotificationItem {
    case notification(objectID: NSManagedObjectID, attribute: Item.StatusAttribute)
    case notificationStatus(objectID: NSManagedObjectID, attribute: Item.StatusAttribute)   // display notification status without card wrapper
    case bottomLoader
}

extension NotificationItem: Equatable {
    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        switch (lhs, rhs) {
        case (.notification(let idLeft, _), .notification(let idRight, _)):
            return idLeft == idRight
        case (.notificationStatus(let idLeft, _), .notificationStatus(let idRight, _)):
            return idLeft == idRight
        case (.bottomLoader, .bottomLoader):
            return true
        default:
            return false
        }
    }
}

extension NotificationItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .notification(let id, _):
            hasher.combine(id)
        case .notificationStatus(let id, _):
            hasher.combine(id)
        case .bottomLoader:
            hasher.combine(String(describing: NotificationItem.bottomLoader.self))
        }
    }
}

extension NotificationItem {
    var statusObjectItem: StatusObjectItem? {
        switch self {
        case .notification(let objectID, _):
            return .mastodonNotification(objectID: objectID)
        case .notificationStatus(let objectID, _):
            return .mastodonNotification(objectID: objectID)
        case .bottomLoader:
            return nil
        }
    }
}
