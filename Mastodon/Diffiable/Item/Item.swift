//
//  Item.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import DifferenceKit

/// Note: update Equatable when change case
enum Item {
    // timeline
    case homeTimelineIndex(objectID: NSManagedObjectID, attribute: StatusAttribute)
    
    // thread
    case root(statusObjectID: NSManagedObjectID, attribute: StatusAttribute)
    case reply(statusObjectID: NSManagedObjectID, attribute: StatusAttribute)
    case leaf(statusObjectID: NSManagedObjectID, attribute: StatusAttribute)
    case leafBottomLoader(statusObjectID: NSManagedObjectID)

    // normal list
    case status(objectID: NSManagedObjectID, attribute: StatusAttribute)

    // loader
    case homeMiddleLoader(upperTimelineIndexAnchorObjectID: NSManagedObjectID)
    case publicMiddleLoader(statusID: String)
    case topLoader
    case bottomLoader
    
    case emptyStateHeader(attribute: EmptyStateHeaderAttribute)
    
    // reports
    case reportStatus(objectID: NSManagedObjectID, attribute: ReportStatusAttribute)
}

extension Item {
    class StatusAttribute {
        var isSeparatorLineHidden: Bool

        /// is media loaded or not
        let isImageLoaded = CurrentValueSubject<Bool, Never>(false)

        /// flag for current sensitive content reveal state
        ///
        /// - true: displaying sensitive content
        /// - false: displaying content warning overlay
        let isRevealing = CurrentValueSubject<Bool, Never>(false)

        init(isSeparatorLineHidden: Bool = false) {
            self.isSeparatorLineHidden = isSeparatorLineHidden
        }
    }
        
    class EmptyStateHeaderAttribute: Hashable {
        let id = UUID()
        let reason: Reason
        
        enum Reason: Equatable {
            case noStatusFound
            case blocking(name: String?)
            case blocked(name: String?)
            case suspended(name: String?)
            
            static func == (lhs: Item.EmptyStateHeaderAttribute.Reason, rhs: Item.EmptyStateHeaderAttribute.Reason) -> Bool {
                switch (lhs, rhs) {
                case (.noStatusFound, noStatusFound): return true
                case (.blocking(let nameLeft), blocking(let nameRight)): return nameLeft == nameRight
                case (.blocked(let nameLeft), blocked(let nameRight)): return nameLeft == nameRight
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
    
    class ReportStatusAttribute: StatusAttribute {
        var isSelected: Bool
        
        init(isSeparatorLineHidden: Bool = false, isSelected: Bool = false) {
            self.isSelected = isSelected
            super.init(isSeparatorLineHidden: isSeparatorLineHidden)
        }
    }
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        switch (lhs, rhs) {
        case (.homeTimelineIndex(let objectIDLeft, _), .homeTimelineIndex(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.root(let objectIDLeft, _), .root(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.reply(let objectIDLeft, _), .reply(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.leaf(let objectIDLeft, _), .leaf(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.leafBottomLoader(let objectIDLeft), .leafBottomLoader(let objectIDRight)):
            return objectIDLeft == objectIDRight
        case (.status(let objectIDLeft, _), .status(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        case (.homeMiddleLoader(let upperLeft), .homeMiddleLoader(let upperRight)):
            return upperLeft == upperRight
        case (.publicMiddleLoader(let upperLeft), .publicMiddleLoader(let upperRight)):
            return upperLeft == upperRight
        case (.topLoader, .topLoader):
            return true
        case (.bottomLoader, .bottomLoader):
            return true
        case (.emptyStateHeader(let attributeLeft), .emptyStateHeader(let attributeRight)):
            return attributeLeft == attributeRight
        case (.reportStatus(let objectIDLeft, _), .reportStatus(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
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
        case .root(let objectID, _):
            hasher.combine(objectID)
        case .reply(let objectID, _):
            hasher.combine(objectID)
        case .leaf(let objectID, _):
            hasher.combine(objectID)
        case .leafBottomLoader(let objectID):
            hasher.combine(objectID)
        case .status(let objectID, _):
            hasher.combine(objectID)
        case .homeMiddleLoader(upperTimelineIndexAnchorObjectID: let upper):
            hasher.combine(String(describing: Item.homeMiddleLoader.self))
            hasher.combine(upper)
        case .publicMiddleLoader(let upper):
            hasher.combine(String(describing: Item.publicMiddleLoader.self))
            hasher.combine(upper)
        case .topLoader:
            hasher.combine(String(describing: Item.topLoader.self))
        case .bottomLoader:
            hasher.combine(String(describing: Item.bottomLoader.self))
        case .emptyStateHeader(let attribute):
            hasher.combine(attribute)
        case .reportStatus(let objectID, _):
            hasher.combine(objectID)
        }
    }
}

extension Item: Differentiable { }

extension Item {
    var statusObjectItem: StatusObjectItem? {
        switch self {
        case .homeTimelineIndex(let objectID, _):
            return .homeTimelineIndex(objectID: objectID)
        case .root(let objectID, _),
             .reply(let objectID, _),
             .leaf(let objectID, _),
             .status(let objectID, _),
             .reportStatus(let objectID, _):
            return .status(objectID: objectID)
        case .leafBottomLoader,
             .homeMiddleLoader,
             .publicMiddleLoader,
             .topLoader,
             .bottomLoader,
             .emptyStateHeader:
            return nil
        }
    }
}
