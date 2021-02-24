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
        timelinePostTableViewCellDelegate: StatusTableViewCellDelegate,
        timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate
    ) {
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()

        diffableDataSource = StatusSection.tableViewDiffableDataSource(
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
        var oldSnapshotAttributeDict: [NSManagedObjectID: Item.StatusTimelineAttribute] = [:]
        for item in self.items.value {
            guard case let .toot(objectID, attribute) = item else { continue }
            oldSnapshotAttributeDict[objectID] = attribute
        }
        
        var items = [Item]()
        for (_, toot) in indexTootTuples {
            let attribute = oldSnapshotAttributeDict[toot.objectID] ?? Item.StatusTimelineAttribute(isStatusTextSensitive: toot.sensitive)
            items.append(Item.toot(objectID: toot.objectID, attribute: attribute))
            if tootIDsWhichHasGap.contains(toot.id) {
                items.append(Item.publicMiddleLoader(tootID: toot.id))
            }
        }

        self.items.value = items
    }
}
