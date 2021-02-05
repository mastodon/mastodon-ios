//
//  Item.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

/// Note: update Equatable when change case
enum Item {
    // normal list
    case toot(objectID: NSManagedObjectID)

    // loader
    case middleLoader(tootID: String)
    case bottomLoader
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        switch (lhs, rhs) {
        case (.toot(let objectIDLeft), .toot(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.bottomLoader, .bottomLoader):
            return true
        case (.middleLoader(let upperLeft), .middleLoader(let upperRight)):
            return upperLeft == upperRight
        default:
            return false
        }
    }
}

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .toot(let objectID):
            hasher.combine(objectID)
        case .middleLoader(let upper):
            hasher.combine(String(describing: Item.middleLoader.self))
            hasher.combine(upper)
        case .bottomLoader:
            hasher.combine(String(describing: Item.bottomLoader.self))
        }
    }
}
