//
//  NotificationViewModel+Diffable.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import CoreDataStack
import os.log
import UIKit
import MastodonSDK

extension NotificationViewModel {
    func setupDiffableDataSource(
        for tableView: UITableView,
        delegate: NotificationTableViewCellDelegate,
        dependency: NeedsDependency
    ) {
        diffableDataSource = NotificationSection.tableViewDiffableDataSource(
            for: tableView,
            managedObjectContext: context.managedObjectContext,
            delegate: delegate,
            dependency: dependency
        )

        var snapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
        snapshot.appendSections([.main])
        diffableDataSource.apply(snapshot)

        // workaround to append loader wrong animation issue
        snapshot.appendItems([.bottomLoader], toSection: .main)
        diffableDataSource.apply(snapshot)
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
        
        let predicate: NSPredicate = {
            let notificationTypePredicate = MastodonNotification.predicate(
                validTypesRaws: Mastodon.Entity.Notification.NotificationType.knownCases.map { $0.rawValue }
            )
            return fetchedResultsController.fetchRequest.predicate.flatMap {
                NSCompoundPredicate(andPredicateWithSubpredicates: [$0, notificationTypePredicate])
            } ?? notificationTypePredicate
        }()
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
                    return NotificationItem.notification(objectID: notification.objectID, attribute: attribute)
                }
                newSnapshot.appendItems(items, toSection: .main)
                if !notifications.isEmpty, self.noMoreNotification.value == false {
                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
                }

                self.isFetchingLatestNotification.value = false

                diffableDataSource.apply(newSnapshot, animatingDifferences: false) { [weak self] in
                    guard let self = self else { return }
                    self.dataSourceDidUpdated.send()
                }
            }
        }
    }

}
