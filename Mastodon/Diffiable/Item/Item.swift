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
    case homeTimelineIndex(objectID: NSManagedObjectID, attribute: Attribute)

    // normal list
    case toot(objectID: NSManagedObjectID)

    // loader
    case homeMiddleLoader(upperTimelineIndexAnchorObjectID: NSManagedObjectID)
    case publicMiddleLoader(tootID: String)
    case bottomLoader
}

extension Item {
    class Attribute: Hashable {
        var separatorLineStyle: SeparatorLineStyle = .indent

        static func == (lhs: Item.Attribute, rhs: Item.Attribute) -> Bool {
            return lhs.separatorLineStyle == rhs.separatorLineStyle
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(separatorLineStyle)
        }

        enum SeparatorLineStyle {
            case indent // alignment to name label
            case expand // alignment to table view two edges
            case normal // alignment to readable guideline
        }
    }
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimelineIndex(let objectIDLeft, _), .homeTimelineIndex(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.toot(let objectIDLeft), .toot(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.bottomLoader, .bottomLoader):
            return true
        case (.publicMiddleLoader(let upperLeft), .publicMiddleLoader(let upperRight)):
            return upperLeft == upperRight
        case (.homeMiddleLoader(let upperLeft), .homeMiddleLoader(let upperRight)):
            return upperLeft == upperRight
        default:
            return false
        }
    }
}

extension Item: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .homeTimelineIndex(let objectID, _):
            hasher.combine(objectID)
        case .toot(let objectID):
            hasher.combine(objectID)
        case .publicMiddleLoader(let upper):
            hasher.combine(String(describing: Item.publicMiddleLoader.self))
            hasher.combine(upper)
        case .homeMiddleLoader(upperTimelineIndexAnchorObjectID: let upper):
            hasher.combine(String(describing: Item.homeMiddleLoader.self))
            hasher.combine(upper)
        case .bottomLoader:
            hasher.combine(String(describing: Item.bottomLoader.self))
        }
    }
}
