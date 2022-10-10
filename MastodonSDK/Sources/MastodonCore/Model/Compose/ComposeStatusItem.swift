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
import CoreDataStack

/// Note: update Equatable when change case
enum ComposeStatusItem {
    case replyTo(record: ManagedObjectRecord<Status>)
    case input(replyTo: ManagedObjectRecord<Status>?, attribute: ComposeStatusAttribute)
    case attachment(attachmentAttribute: ComposeStatusAttachmentAttribute)
    case pollOption(pollOptionAttributes: [ComposeStatusPollItem.PollOptionAttribute], pollExpiresOptionAttribute: ComposeStatusPollItem.PollExpiresOptionAttribute)
}

extension ComposeStatusItem: Hashable { }

extension ComposeStatusItem {
    final class ComposeStatusAttribute: Hashable {
        private let id = UUID()
        
        @Published var author: ManagedObjectRecord<MastodonUser>?

        @Published var composeContent: String?
        
        @Published var isContentWarningComposing = false
        @Published var contentWarningContent = ""
        
        static func == (lhs: ComposeStatusAttribute, rhs: ComposeStatusAttribute) -> Bool {
            return lhs.author == rhs.author
                && lhs.composeContent == rhs.composeContent
                && lhs.isContentWarningComposing == rhs.isContentWarningComposing
                && lhs.contentWarningContent == rhs.contentWarningContent
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
