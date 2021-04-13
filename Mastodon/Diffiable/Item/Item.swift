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
    case homeTimelineIndex(objectID: NSManagedObjectID, attribute: StatusAttribute)

    // normal list
    case status(objectID: NSManagedObjectID, attribute: StatusAttribute)

    // loader
    case homeMiddleLoader(upperTimelineIndexAnchorObjectID: NSManagedObjectID)
    case publicMiddleLoader(statusID: String)
    case bottomLoader
    
    case emptyStateHeader(attribute: EmptyStateHeaderAttribute)
}

protocol StatusContentWarningAttribute {
    var isStatusTextSensitive: Bool? { get set }
    var isStatusSensitive: Bool? { get set }
}

extension Item {
    class StatusAttribute: StatusContentWarningAttribute {
        var isStatusTextSensitive: Bool?
        var isStatusSensitive: Bool?

        init(
            isStatusTextSensitive: Bool? = nil,
            isStatusSensitive: Bool? = nil
        ) {
            self.isStatusTextSensitive = isStatusTextSensitive
            self.isStatusSensitive = isStatusSensitive
        }
        
        // delay attribute init
        func setupForStatus(status: Status) {
            if isStatusTextSensitive == nil {
                isStatusTextSensitive = {
                    guard let spoilerText = status.spoilerText, !spoilerText.isEmpty else { return false }
                    return true
                }()
            }
            
            if isStatusSensitive == nil {
                isStatusSensitive = status.sensitive
            }
        }
    }
    
    class EmptyStateHeaderAttribute: Hashable {
        let id = UUID()
        let reason: Reason
        
        enum Reason: Equatable {
            case noStatusFound
            case blocking
            case blocked
            case suspended(name: String?)
            
            static func == (lhs: Item.EmptyStateHeaderAttribute.Reason, rhs: Item.EmptyStateHeaderAttribute.Reason) -> Bool {
                switch (lhs, rhs) {
                case (.noStatusFound, noStatusFound): return true
                case (.blocking, blocking): return true
                case (.blocked, blocked): return true
                case (.suspended(let nameLeft), .suspended(let nameRight)):   return nameLeft == nameRight
                default: return false
                }
            }
        }
        
        init(reason: Reason) {
            self.reason = reason
        }
        
        static func == (lhs: Item.EmptyStateHeaderAttribute, rhs: Item.EmptyStateHeaderAttribute) -> Bool {
            return lhs.reason == rhs.reason
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimelineIndex(let objectIDLeft, _), .homeTimelineIndex(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.status(let objectIDLeft, _), .status(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.homeMiddleLoader(let upperLeft), .homeMiddleLoader(let upperRight)):
            return upperLeft == upperRight
        case (.publicMiddleLoader(let upperLeft), .publicMiddleLoader(let upperRight)):
            return upperLeft == upperRight
        case (.bottomLoader, .bottomLoader):
            return true
        case (.emptyStateHeader(let attributeLeft), .emptyStateHeader(let attributeRight)):
            return attributeLeft == attributeRight
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
        case .status(let objectID, _):
            hasher.combine(objectID)
        case .homeMiddleLoader(upperTimelineIndexAnchorObjectID: let upper):
            hasher.combine(String(describing: Item.homeMiddleLoader.self))
            hasher.combine(upper)
        case .publicMiddleLoader(let upper):
            hasher.combine(String(describing: Item.publicMiddleLoader.self))
            hasher.combine(upper)
        case .bottomLoader:
            hasher.combine(String(describing: Item.bottomLoader.self))
        case .emptyStateHeader(let attribute):
            hasher.combine(attribute)
        }
    }
}
