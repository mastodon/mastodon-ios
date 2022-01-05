//
//  ComposeStatusItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import Foundation
import Combine
import CoreData
import MastodonMeta

/// Note: update Equatable when change case
enum ComposeStatusItem {
    case replyTo(statusObjectID: NSManagedObjectID)
    case input(replyToStatusObjectID: NSManagedObjectID?, attribute: ComposeStatusAttribute)
    case attachment(attachmentAttribute: ComposeStatusAttachmentAttribute)
    case pollOption(pollOptionAttributes: [ComposeStatusPollItem.PollOptionAttribute], pollExpiresOptionAttribute: ComposeStatusPollItem.PollExpiresOptionAttribute)
}

extension ComposeStatusItem: Hashable { }

extension ComposeStatusItem {
    final class ComposeStatusAttribute: Equatable, Hashable {
        private let id = UUID()
                
        let avatarURL = CurrentValueSubject<URL?, Never>(nil)
        let displayName = CurrentValueSubject<String?, Never>(nil)
        let emojiMeta = CurrentValueSubject<MastodonContent.Emojis, Never>([:])
        let username = CurrentValueSubject<String?, Never>(nil)
        let composeContent = CurrentValueSubject<String?, Never>(nil)
        
        let isContentWarningComposing = CurrentValueSubject<Bool, Never>(false)
        let contentWarningContent = CurrentValueSubject<String, Never>("")
        
        static func == (lhs: ComposeStatusAttribute, rhs: ComposeStatusAttribute) -> Bool {
            return lhs.avatarURL.value == rhs.avatarURL.value &&
                lhs.displayName.value == rhs.displayName.value &&
                lhs.emojiMeta.value == rhs.emojiMeta.value &&
                lhs.username.value == rhs.username.value &&
                lhs.composeContent.value == rhs.composeContent.value &&
                lhs.isContentWarningComposing.value == rhs.isContentWarningComposing.value &&
                lhs.contentWarningContent.value == rhs.contentWarningContent.value
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension ComposeStatusItem {
    final class ComposeStatusAttachmentAttribute: Hashable {
        private let id = UUID()

        var attachmentServices: [MastodonAttachmentService]

        init(attachmentServices: [MastodonAttachmentService]) {
            self.attachmentServices = attachmentServices
        }

        static func == (lhs: ComposeStatusAttachmentAttribute, rhs: ComposeStatusAttachmentAttribute) -> Bool {
            return lhs.attachmentServices == rhs.attachmentServices
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
