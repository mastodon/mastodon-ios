//
//  ComposeStatusItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import Foundation
import CoreData

enum ComposeStatusItem {
    case replyTo(tootObjectID: NSManagedObjectID)
    case toot(attribute: InputAttribute)
}

extension ComposeStatusItem: Hashable { }

extension ComposeStatusItem {
    class InputAttribute: Hashable {
        let hasReplyTo: Bool
        
        init(hasReplyTo: Bool) {
            self.hasReplyTo = hasReplyTo
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(hasReplyTo)
        }
        
        static func == (lhs: ComposeStatusItem.InputAttribute, rhs: ComposeStatusItem.InputAttribute) -> Bool {
            return lhs.hasReplyTo == rhs.hasReplyTo
        }
    }
}
