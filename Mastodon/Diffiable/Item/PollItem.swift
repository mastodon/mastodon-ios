//
//  PollItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import Foundation
import CoreData

enum PollItem {
    case pollOpion(objectID: NSManagedObjectID, attribute: Attribute)
}


extension PollItem {
    class Attribute: Hashable {
        var voted: Bool = false
        
        static func == (lhs: PollItem.Attribute, rhs: PollItem.Attribute) -> Bool {
            return lhs.voted == rhs.voted
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(voted)
        }
    }
}

extension PollItem: Equatable {
    static func == (lhs: PollItem, rhs: PollItem) -> Bool {
        switch (lhs, rhs) {
        case (.pollOpion(let objectIDLeft, _), .pollOpion(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        default:
            return false
        }
    }
}


extension PollItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .pollOpion(let objectID, _):
            hasher.combine(objectID)
        }
    }
}
