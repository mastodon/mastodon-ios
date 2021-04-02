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
        statusTableViewCellDelegate: StatusTableViewCellDelegate,
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
            statusTableViewCellDelegate: statusTableViewCellDelegate,
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

        let indexes = statusIDs.value
        let statuses = fetchedResultsController.fetchedObjects ?? []
        guard statuses.count == indexes.count else { return }
        let indexStatusTuples: [(Int, Status)] = statuses
            .compactMap { status -> (Int, Status)? in
                guard status.deletedAt == nil else { return nil }
                return indexes.firstIndex(of: status.id).map { index in (index, status) }
            }
            .sorted { $0.0 < $1.0 }
        var oldSnapshotAttributeDict: [NSManagedObjectID: Item.StatusAttribute] = [:]
        for item in self.items.value {
            guard case let .status(objectID, attribute) = item else { continue }
            oldSnapshotAttributeDict[objectID] = attribute
        }
        
        var items = [Item]()
        for (_, status) in indexStatusTuples {
            let targetStatus = status.reblog ?? status
            let isStatusTextSensitive: Bool = {
                guard let spoilerText = targetStatus.spoilerText, !spoilerText.isEmpty else { return false }
                return true
            }()
            let attribute = oldSnapshotAttributeDict[status.objectID] ?? Item.StatusAttribute(isStatusTextSensitive: isStatusTextSensitive, isStatusSensitive: targetStatus.sensitive)
            items.append(Item.status(objectID: status.objectID, attribute: attribute))
            if statusIDsWhichHasGap.contains(status.id) {
                items.append(Item.publicMiddleLoader(statusID: status.id))
            }
        }

        self.items.value = items
    }
}
