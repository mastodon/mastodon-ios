//
//  ComposeStatusItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import Foundation
import Combine
import CoreData

enum ComposeStatusItem {
    case replyTo(tootObjectID: NSManagedObjectID)
    case toot(replyToTootObjectID: NSManagedObjectID?, attribute: ComposeTootAttribute)
}

extension ComposeStatusItem: Hashable { }

extension ComposeStatusItem {
    final class ComposeTootAttribute: Equatable, Hashable {
        private let id = UUID()
        
        let avatarURL = CurrentValueSubject<URL?, Never>(nil)
        let displayName = CurrentValueSubject<String?, Never>(nil)
        let username = CurrentValueSubject<String?, Never>(nil)
        let composeContent = CurrentValueSubject<String?, Never>(nil)
        
        static func == (lhs: ComposeTootAttribute, rhs: ComposeTootAttribute) -> Bool {
            return lhs.avatarURL.value == rhs.avatarURL.value &&
                lhs.displayName.value == rhs.displayName.value &&
                lhs.username.value  == rhs.username.value &&
                lhs.composeContent.value == rhs.composeContent.value
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
