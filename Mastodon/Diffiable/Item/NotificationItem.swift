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

    case bottomLoader
}

extension NotificationItem: Equatable {
    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        switch (lhs, rhs) {
        case (.notification(let idLeft, _), .notification(let idRight, _)):
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
        case .bottomLoader:
            hasher.combine(String(describing: NotificationItem.bottomLoader.self))
        }
    }
}
