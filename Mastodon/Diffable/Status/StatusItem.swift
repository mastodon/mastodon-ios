//
//  StatusItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-11.
//

import Foundation
import CoreDataStack
import MastodonUI

enum StatusItem: Hashable {
    case feed(record: ManagedObjectRecord<Feed>)
    case feedLoader(record: ManagedObjectRecord<Feed>)
    case status(record: ManagedObjectRecord<Status>)
    case thread(Thread)
    case topLoader
    case bottomLoader
}
 
extension StatusItem {
    enum Thread: Hashable {
        case root(context: Context)
        case reply(context: Context)
        case leaf(context: Context)
        
        public var record: ManagedObjectRecord<Status> {
            switch self {
            case .root(let threadContext),
                .reply(let threadContext),
                .leaf(let threadContext):
                return threadContext.status
            }
        }
    }
}

extension StatusItem.Thread {
    class Context: Hashable {
        let status: ManagedObjectRecord<Status>
        var displayUpperConversationLink: Bool
        var displayBottomConversationLink: Bool
        
        init(
            status: ManagedObjectRecord<Status>,
            displayUpperConversationLink: Bool = false,
            displayBottomConversationLink: Bool = false
        ) {
            self.status = status
            self.displayUpperConversationLink = displayUpperConversationLink
            self.displayBottomConversationLink = displayBottomConversationLink
        }
        
        static func == (lhs: StatusItem.Thread.Context, rhs: StatusItem.Thread.Context) -> Bool {
            return lhs.status == rhs.status
            && lhs.displayUpperConversationLink == rhs.displayUpperConversationLink
            && lhs.displayBottomConversationLink == rhs.displayBottomConversationLink
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(status)
            hasher.combine(displayUpperConversationLink)
            hasher.combine(displayBottomConversationLink)
        }
    }
}
