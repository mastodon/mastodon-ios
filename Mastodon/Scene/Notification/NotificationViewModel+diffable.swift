//
//  NotificationViewModel+diffable.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import CoreDataStack
import os.log
import UIKit

extension NotificationViewModel {
    func setupDiffableDataSource(
        for tableView: UITableView,
        delegate: NotificationTableViewCellDelegate,
        dependency: NeedsDependency
    ) {
        let timestampUpdatePublisher = Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        diffableDataSource = NotificationSection.tableViewDiffableDataSource(
            for: tableView,
            timestampUpdatePublisher: timestampUpdatePublisher,
            managedObjectContext: context.managedObjectContext,
            delegate: delegate,
            dependency: dependency
        )
    }
}

extension NotificationViewModel: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", (#file as NSString).lastPathComponent, #line, #function)
        
        guard let tableView = self.tableView else { return }
        guard let navigationBar = contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar() else { return }
        
        guard let diffableDataSource = self.diffableDataSource else { return }
        
        let predicate = fetchedResultsController.fetchRequest.predicate
        let parentManagedObjectContext = fetchedResultsController.managedObjectContext
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = parentManagedObjectContext
        
        managedObjectContext.perform {
            let notifications: [MastodonNotification] = {
                let request = MastodonNotification.sortedFetchRequest
                request.returnsObjectsAsFaults = false
                request.predicate = predicate
                do {
                    return try managedObjectContext.fetch(request)
                } catch {
                    assertionFailure(error.localizedDescription)
                    return []
                }
            }()
            
            DispatchQueue.main.async {
                let oldSnapshot = diffableDataSource.snapshot()
                var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
                for item in oldSnapshot.itemIdentifiers {
                    guard case let .notification(objectID, attribute) = item else { continue }
                    oldSnapshotAttributeDict[objectID] = attribute
                }
                var newSnapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
                newSnapshot.appendSections([.main])
                let items: [NotificationItem] = notifications.map { notification in
                    let attribute: Item.StatusAttribute = oldSnapshotAttributeDict[notification.objectID] ?? Item.StatusAttribute()

//                    let attribute: Item.StatusAttribute = {
//                        if let attribute = oldSnapshotAttributeDict[notification.objectID] {
//                            return attribute
//                        } else if let status = notification.status {
//                            let attribute = Item.StatusAttribute()
//                            let isSensitive = status.sensitive || !(status.spoilerText ?? "").isEmpty
//                            attribute.isRevealing.value = !isSensitive
//                            return attribute
//                        } else {
//                            return Item.StatusAttribute()
//                        }
//                    }()
                    return NotificationItem.notification(objectID: notification.objectID, attribute: attribute)
                }
                newSnapshot.appendItems(items, toSection: .main)
                if !notifications.isEmpty, self.noMoreNotification.value == false {
                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
                }
                guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
                    diffableDataSource.apply(newSnapshot, animatingDifferences: false)
                    self.isFetchingLatestNotification.value = false
                    tableView.reloadData()
                    return
                }
                
                diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
                    tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                    tableView.contentOffset.y = tableView.contentOffset.y - difference.offset
                    self.isFetchingLatestNotification.value = false
                }
            }
        }
    }
    
    private struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let targetIndexPath: IndexPath
        let offset: CGFloat
    }
    
    private func calculateReloadSnapshotDifference<T: Hashable>(
        navigationBar: UINavigationBar,
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<NotificationSection, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<NotificationSection, T>
    ) -> Difference<T>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        
        // old snapshot not empty. set source index path to first item if not match
        let sourceIndexPath = UIViewController.topVisibleTableViewCellIndexPath(in: tableView, navigationBar: navigationBar) ?? IndexPath(row: 0, section: 0)
        
        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
        
        if oldSnapshot.itemIdentifiers.elementsEqual(newSnapshot.itemIdentifiers) {
            return nil
        }
        let timelineItem = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: timelineItem) else { return nil }
        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
        
        let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
        return Difference(
            item: timelineItem,
            sourceIndexPath: sourceIndexPath,
            targetIndexPath: targetIndexPath,
            offset: offset
        )
    }
}
