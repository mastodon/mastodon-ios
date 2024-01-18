//
//  StatusItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-11.
//

import Foundation
import CoreDataStack
import MastodonUI
import MastodonSDK

enum StatusItem: Hashable {
    case feed(record: MastodonFeed)
    case feedLoader(record: MastodonFeed)
    case status(record: MastodonStatus)
    case thread(Thread)
    case topLoader
    case bottomLoader
}
 
extension StatusItem {
    enum Thread: Hashable {
        case root(context: Context)
        case reply(context: Context)
        case leaf(context: Context)
        
        public var record: MastodonStatus {
            get {
                switch self {
                case .root(let threadContext),
                    .reply(let threadContext),
                    .leaf(let threadContext):
                    return threadContext.status
                }
            }
            
            set {
                switch self {
                case let .root(threadContext):
                    self = .root(context: .init(
                        status: newValue,
                        displayUpperConversationLink: threadContext.displayUpperConversationLink,
                        displayBottomConversationLink: threadContext.displayBottomConversationLink)
                    )
                    
                case let .reply(threadContext):
                    self = .reply(context: .init(
                        status: newValue,
                        displayUpperConversationLink: threadContext.displayUpperConversationLink,
                        displayBottomConversationLink: threadContext.displayBottomConversationLink)
                    )
                    
                case let .leaf(threadContext):
                    self = .leaf(context: .init(
                        status: newValue,
                        displayUpperConversationLink: threadContext.displayUpperConversationLink,
                        displayBottomConversationLink: threadContext.displayBottomConversationLink)
                    )

                }
            }
        }
    }
}

extension StatusItem.Thread {
    class Context: Hashable {
        let status: MastodonStatus
        var displayUpperConversationLink: Bool
        var displayBottomConversationLink: Bool
        
        init(
            status: MastodonStatus,
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
