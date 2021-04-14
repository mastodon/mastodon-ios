//
//  NotificationViewModel+diffable.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

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
        guard let userid = activeMastodonAuthenticationBox.value?.userID else {
            return
        }
        diffableDataSource = NotificationSection.tableViewDiffableDataSource(
            for: tableView,
            timestampUpdatePublisher: timestampUpdatePublisher,
            managedObjectContext: context.managedObjectContext,
            delegate: delegate,
            dependency: dependency,
            requestUserID: userid
        )
    }
    
}

extension NotificationViewModel: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard let tableView = self.tableView else { return }
        guard let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar() else { return }
        
        guard let diffableDataSource = self.diffableDataSource else { return }
        let oldSnapshot = diffableDataSource.snapshot()
        
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
            
            var newSnapshot = NSDiffableDataSourceSnapshot<NotificationSection, NotificationItem>()
            newSnapshot.appendSections([.main])
            newSnapshot.appendItems(notifications.map({NotificationItem.notification(objectID: $0.objectID)}), toSection: .main)
            if !notifications.isEmpty {
                newSnapshot.appendItems([.bottomLoader], toSection: .main)
            }
            
            DispatchQueue.main.async {
                guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
                    diffableDataSource.apply(newSnapshot)
                    self.isFetchingLatestNotification.value = false
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
