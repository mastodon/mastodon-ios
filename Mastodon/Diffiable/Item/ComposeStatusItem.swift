//
//  ComposeStatusItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import Foundation
import Combine
import CoreData

/// Note: update Equatable when change case
enum ComposeStatusItem {
    case replyTo(statusObjectID: NSManagedObjectID)
    case input(replyToStatusObjectID: NSManagedObjectID?, attribute: ComposeStatusAttribute)
    case attachment(attachmentService: MastodonAttachmentService)
    case poll(attribute: ComposePollAttribute)
    case newPoll
}

extension ComposeStatusItem: Equatable { }

extension ComposeStatusItem: Hashable { }

extension ComposeStatusItem {
    final class ComposeStatusAttribute: Equatable, Hashable {
        private let id = UUID()
        
        let avatarURL = CurrentValueSubject<URL?, Never>(nil)
        let displayName = CurrentValueSubject<String?, Never>(nil)
        let username = CurrentValueSubject<String?, Never>(nil)
        let composeContent = CurrentValueSubject<String?, Never>(nil)
        
        static func == (lhs: ComposeStatusAttribute, rhs: ComposeStatusAttribute) -> Bool {
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

extension ComposeStatusItem {
    final class ComposePollAttribute: Equatable, Hashable {
        private let id = UUID()
        
        let option = CurrentValueSubject<String, Never>("")
        
        static func == (lhs: ComposePollAttribute, rhs: ComposePollAttribute) -> Bool {
            return lhs.id == rhs.id &&
                lhs.option.value == rhs.option.value
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
