//
//  NotificationItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import Foundation

enum NotificationItem {
    case notification(objectID: NSManagedObjectID)

    case bottomLoader
}

extension NotificationItem: Equatable {
    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool {
        switch (lhs, rhs) {
        case (.bottomLoader, .bottomLoader):
            return true
        case (.notification(let idLeft), .notification(let idRight)):
            return idLeft == idRight
        default:
            return false
        }
    }
}

extension NotificationItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .notification(let id):
            hasher.combine(id)
        case .bottomLoader:
            hasher.combine(String(describing: NotificationItem.bottomLoader.self))
        }
    }
}
