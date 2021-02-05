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
        timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate,
        timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate
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
            timelinePostTableViewCellDelegate: timelinePostTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: timelineMiddleLoaderTableViewCellDelegate
        )
        items.value = []
        stateMachine.enter(PublicTimelineViewModel.State.Loading.self)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension PublicTimelineViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)

        let indexes = tootIDs.value
        let toots = fetchedResultsController.fetchedObjects ?? []
        guard toots.count == indexes.count else { return }
        let indexTootTuples: [(Int, Toot)] = toots
            .compactMap { toot -> (Int, Toot)? in
                guard toot.deletedAt == nil else { return nil }
                return indexes.firstIndex(of: toot.id).map { index in (index, toot) }
            }
            .sorted { $0.0 < $1.0 }
        var items = [Item]()
        for tuple in indexTootTuples {
            items.append(Item.toot(objectID: tuple.1.objectID))
            if tootIDsWhichHasGap.contains(tuple.1.id) {
                items.append(Item.middleLoader(tootID: tuple.1.id))
            }
        }

        self.items.value = items
    }
}
