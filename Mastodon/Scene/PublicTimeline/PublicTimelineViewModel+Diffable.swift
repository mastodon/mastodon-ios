//
//  PublicTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import CoreData
import CoreDataStack
import os.log
import UIKit

extension PublicTimelineViewModel {
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate
    ) {
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()

        diffableDataSource = TimelineSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            managedObjectContext: fetchedResultsController.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher,
            timelinePostTableViewCellDelegate: timelinePostTableViewCellDelegate
        )
        items.value = []
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PublicTimelineViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)

        let indexes = tootIDs.value
        let toots = fetchedResultsController.fetchedObjects ?? []
        guard toots.count == indexes.count else { return }
        let items: [Item] = toots
            .compactMap { toot -> (Int, Toot)? in
                guard toot.deletedAt == nil else { return nil }
                return indexes.firstIndex(of: toot.id).map { index in (index, toot) }
            }
            .sorted { $0.0 < $1.0 }
            .map { Item.toot(objectID: $0.1.objectID) }
        self.items.value = items
    }
}
