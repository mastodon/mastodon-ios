// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import CoreData
import CoreDataStack
import MastodonSDK

extension Persistence.StatusEdit {

    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        statusEdits: [Mastodon.Entity.StatusEdit],
        forStatus status: Status
    ) {
        guard statusEdits.isEmpty == false else { return }

        // remove all edits for status

        if let editHistory = status.editHistory {
            for statusEdit in Array(editHistory) {
                managedObjectContext.delete(statusEdit)
            }
        }
        status.update(editHistory: Set())
        let persistedEdits = create(in: managedObjectContext, statusEdits: statusEdits, forStatus: status)
        status.update(editHistory: Set(persistedEdits))
    }

    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        statusEdits: [Mastodon.Entity.StatusEdit],
        forStatus status: Status
    ) -> [StatusEdit] {

        var entries: [StatusEdit] = []

//        for statusEdit in statusEdits {
//            let property = StatusEdit.Property(createdAt: statusEdit.createdAt, content: statusEdit.content, sensitive: statusEdit.sensitive, spoilerText: statusEdit.spoilerText, emojis: statusEdit.mastodonEmojis, attachments: statusEdit.mastodonAttachments, poll: statusEdit.poll.map { StatusEdit.Poll(options: $0.options.map { StatusEdit.Poll.Option(title: $0.title) } ) })
//            let statusEditEntry = StatusEdit.insert(into: managedObjectContext, property: property)
//
//            entries.append(statusEditEntry)
//        }

        status.update(editHistory: Set(entries))

        return entries
    }
}

