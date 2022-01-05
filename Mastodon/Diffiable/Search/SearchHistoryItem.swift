//
//  SearchHistoryItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import Foundation
import CoreData

enum SearchHistoryItem {
    case account(objectID: NSManagedObjectID)
    case hashtag(objectID: NSManagedObjectID)
    case status(objectID: NSManagedObjectID, attribute: Item.StatusAttribute)
}

extension SearchHistoryItem: Hashable {
    static func == (lhs: SearchHistoryItem, rhs: SearchHistoryItem) -> Bool {
        switch (lhs, rhs) {
        case (.account(let objectIDLeft), account(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.hashtag(let objectIDLeft), hashtag(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.status(let objectIDLeft, _), status(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .account(let objectID):
            hasher.combine(objectID)
        case .hashtag(let objectID):
            hasher.combine(objectID)
        case .status(let objectID, _):
            hasher.combine(objectID)
        }
    }
}
