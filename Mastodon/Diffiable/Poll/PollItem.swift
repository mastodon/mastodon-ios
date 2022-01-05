//
//  PollItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import Foundation
import CoreData

/// Note: update Equatable when change case
enum PollItem {
    case option(objectID: NSManagedObjectID, attribute: Attribute)
}


extension PollItem {
    class Attribute: Hashable {
        
        enum SelectState: Equatable, Hashable {
            case none
            case off
            case on
        }
        
        enum VoteState: Equatable, Hashable {
            case hidden
            case reveal(voted: Bool, percentage: Double, animated: Bool)
        }
        
        var selectState: SelectState
        var voteState: VoteState
        
        init(selectState: SelectState, voteState: VoteState) {
            self.selectState = selectState
            self.voteState = voteState
        }
        
        static func == (lhs: PollItem.Attribute, rhs: PollItem.Attribute) -> Bool {
            return lhs.selectState == rhs.selectState &&
                lhs.voteState == rhs.voteState
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(selectState)
            hasher.combine(voteState)
        }
    }
}

extension PollItem: Equatable {
    static func == (lhs: PollItem, rhs: PollItem) -> Bool {
        switch (lhs, rhs) {
        case (.option(let objectIDLeft, _), .option(let objectIDRight, _)):
            return objectIDLeft == objectIDRight
        }
    }
}


extension PollItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .option(let objectID, _):
            hasher.combine(objectID)
        }
    }
}
