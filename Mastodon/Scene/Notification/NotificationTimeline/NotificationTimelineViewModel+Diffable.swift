//
//  NotificationTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import UIKit
import CoreData
import MastodonSDK

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
        
        dataController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                Task {
                    let oldSnapshot = diffableDataSource.snapshot()
                    var newSnapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem> = {
                        let newItems = records.map { record in
                            NotificationItem.feed(record: record)
                        }
                        var snapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
                        snapshot.appendSections([.main])
                        if self.scope == .everything, let notificationPolicy = self.notificationPolicy, notificationPolicy.summary.pendingRequestsCount > 0 {
                            snapshot.appendItems([.filteredNotifications(policy: notificationPolicy)])
                        }
                        snapshot.appendItems(newItems.removingDuplicates(), toSection: .main)
                        return snapshot
                    }()

                    let anchors: [MastodonFeed] = records.filter { $0.hasMore == true }
                    let itemIdentifiers = newSnapshot.itemIdentifiers
                    for (index, item) in itemIdentifiers.enumerated() {
                        guard case let .feed(record) = item else { continue }
                        guard anchors.contains(where: { feed in feed.id == record.id }) else { continue }
                        let isLast = index + 1 == itemIdentifiers.count
                        if isLast {
                            newSnapshot.insertItems([.bottomLoader], afterItem: item)
                        } else {
                            newSnapshot.insertItems([.feedLoader(record: record)], afterItem: item)
                        }
                    }

                    let hasChanges = newSnapshot.itemIdentifiers != oldSnapshot.itemIdentifiers
                    if !hasChanges {
                        self.didLoadLatest.send()
                        return
                    }

                    await self.updateSnapshotUsingReloadData(snapshot: newSnapshot)
                    self.didLoadLatest.send()
                }   // end Task
            }
            .store(in: &disposeBag)
    }   // end func setupDiffableDataSource

}

extension NotificationTimelineViewModel {
    @MainActor func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>
    ) async {
        await self.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
    }
    
}
