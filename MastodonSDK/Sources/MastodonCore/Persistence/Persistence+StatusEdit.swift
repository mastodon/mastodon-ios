// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import CoreData
import CoreDataStack
import MastodonSDK

extension Persistence.StatusEdit {

    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        forStatusID statusID: Status.ID
    ) -> [StatusEdit] {
        //        let request = StatusEditHistoryEntry.fetchRequest()
        //        let statusEdit = try? managedObjectContext.fetch(request).first as? StatusEditHistoryEntry
        //        return statusEdit
        return []
    }

    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        statusEdits: [Mastodon.Entity.StatusEdit],
        forStatus status: Status
    ) {
        guard statusEdits.isEmpty == false else { return }

        let persistedEdits = create(in: managedObjectContext, statusEdits: statusEdits, forStatus: status)
        status.update(editHistory: Set(persistedEdits))
    }

    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        statusEdits: [Mastodon.Entity.StatusEdit],
        forStatus status: Status
    ) -> [StatusEdit] {

        var entries: [StatusEdit] = []

        for statusEdit in statusEdits {
            let property = StatusEdit.Property(createdAt: statusEdit.createdAt, content: statusEdit.content, sensitive: statusEdit.sensitive, spoilerText: statusEdit.spoilerText)
            let statusEditEntry = StatusEdit.insert(into: managedObjectContext, property: property)

            entries.append(statusEditEntry)
        }

        status.update(editHistory: Set(entries))

        return entries
    }
}

