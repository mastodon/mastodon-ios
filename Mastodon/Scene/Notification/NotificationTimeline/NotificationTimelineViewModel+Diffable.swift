//
//  NotificationTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension NotificationTimelineViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        notificationTableViewCellDelegate: NotificationTableViewCellDelegate
    ) {
        diffableDataSource = NotificationSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: NotificationSection.Configuration(
                authContext: authContext,
                notificationTableViewCellDelegate: notificationTableViewCellDelegate,
                filterContext: .notifications,
                activeFilters: context.statusFilterService.$activeFilters
            )
        )

        var snapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        feedFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(records.count) objects")

                Task {
                    let start = CACurrentMediaTime()
                    defer {
                        let end = CACurrentMediaTime()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cost \(end - start, format: .fixed(precision: 4))s to process \(records.count) feeds")
                    }
                    let oldSnapshot = diffableDataSource.snapshot()
                    var newSnapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem> = {
                        let newItems = records.map { record in
                            NotificationItem.feed(record: record)
                        }
                        var snapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
                        snapshot.appendSections([.main])
                        snapshot.appendItems(newItems, toSection: .main)
                        return snapshot
                    }()

                    let parentManagedObjectContext = self.context.managedObjectContext
                    let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
                    managedObjectContext.parent = parentManagedObjectContext
                    try? await managedObjectContext.perform {
                        let anchors: [Feed] = {
                            let request = Feed.sortedFetchRequest
                            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                                Feed.hasMorePredicate(),
                                self.feedFetchedResultsController.predicate,
                            ])
                            do {
                                return try managedObjectContext.fetch(request)
                            } catch {
                                assertionFailure(error.localizedDescription)
                                return []
                            }
                        }()
                        
                        let itemIdentifiers = newSnapshot.itemIdentifiers
                        for (index, item) in itemIdentifiers.enumerated() {
                            guard case let .feed(record) = item else { continue }
                            guard anchors.contains(where: { feed in feed.objectID == record.objectID }) else { continue }
                            let isLast = index + 1 == itemIdentifiers.count
                            if isLast {
                                newSnapshot.insertItems([.bottomLoader], afterItem: item)
                            } else {
                                newSnapshot.insertItems([.feedLoader(record: record)], afterItem: item)
                            }
                        }
                    }

                    let hasChanges = newSnapshot.itemIdentifiers != oldSnapshot.itemIdentifiers
                    if !hasChanges {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot not changes")
                        self.didLoadLatest.send()
                        return
                    } else {
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): snapshot has changes")
                    }

                    await self.updateSnapshotUsingReloadData(snapshot: newSnapshot)
                    self.didLoadLatest.send()
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }   // end Task
            }
            .store(in: &disposeBag)
    }   // end func setupDiffableDataSource

}

extension NotificationTimelineViewModel {
    
    @MainActor func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>,
        animatingDifferences: Bool
    ) async {
        diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    @MainActor func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>
    ) async {
        if #available(iOS 15.0, *) {
            await self.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
        } else {
            diffableDataSource?.applySnapshot(snapshot, animated: false, completion: nil)
        }
    }
    
}
