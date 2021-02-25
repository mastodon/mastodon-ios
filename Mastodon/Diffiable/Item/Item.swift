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
    // timeline
    case homeTimelineIndex(objectID: NSManagedObjectID, attribute: StatusTimelineAttribute)

    // normal list
    case toot(objectID: NSManagedObjectID, attribute: StatusTimelineAttribute)

    // loader
    case homeMiddleLoader(upperTimelineIndexAnchorObjectID: NSManagedObjectID)
    case publicMiddleLoader(tootID: String)
    case bottomLoader
}

protocol StatusContentWarningAttribute {
    var isStatusTextSensitive: Bool { get set }
    var isStatusSensitive: Bool { get set }
}

extension Item {
    class StatusTimelineAttribute: Hashable, StatusContentWarningAttribute {
        var isStatusTextSensitive: Bool
        var isStatusSensitive: Bool

        public init(
            isStatusTextSensitive: Bool,
            isStatusSensitive: Bool
        ) {
            self.isStatusTextSensitive = isStatusTextSensitive
            self.isStatusSensitive = isStatusSensitive
        }
        
        static func == (lhs: Item.StatusTimelineAttribute, rhs: Item.StatusTimelineAttribute) -> Bool {
            return lhs.isStatusTextSensitive == rhs.isStatusTextSensitive &&
                lhs.isStatusSensitive == rhs.isStatusSensitive
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isStatusTextSensitive)
            hasher.combine(isStatusSensitive)
        }

    }
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimelineIndex(let objectIDLeft, _), .homeTimelineIndex(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.toot(let objectIDLeft, _), .toot(let objectIDRight, _)):
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
        case .toot(let objectID, _):
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
