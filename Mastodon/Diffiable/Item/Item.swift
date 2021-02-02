//
//  Item.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import Foundation
import CoreData
import MastodonSDK
import CoreDataStack

/// Note: update Equatable when change case
enum Item {
    
    // normal list
    case toot(objectID: NSManagedObjectID)
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        switch (lhs, rhs) {
        case (.toot(let objectIDLeft), .toot(let objectIDRight)):
            return objectIDLeft == objectIDRight
        }
    }
}

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .toot(let objectID):
            hasher.combine(objectID)
        }
    }
}

