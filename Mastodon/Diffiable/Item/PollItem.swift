//
//  PollItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import Foundation
import CoreData

enum PollItem {
    case opion(objectID: NSManagedObjectID, attribute: Attribute)
}


extension PollItem {
    class Attribute: Hashable {
        // var pollVotable: Bool
        var isOptionVoted: Bool
        
        init(isOptionVoted: Bool) {
            // self.pollVotable = pollVotable
            self.isOptionVoted = isOptionVoted
        }
        
        static func == (lhs: PollItem.Attribute, rhs: PollItem.Attribute) -> Bool {
            return lhs.isOptionVoted == rhs.isOptionVoted
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(isOptionVoted)
        }
    }
}

extension PollItem: Equatable {
    static func == (lhs: PollItem, rhs: PollItem) -> Bool {
        switch (lhs, rhs) {
        case (.opion(let objectIDLeft, _), .opion(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        }
    }
}


extension PollItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .opion(let objectID, _):
            hasher.combine(objectID)
        }
    }
}
