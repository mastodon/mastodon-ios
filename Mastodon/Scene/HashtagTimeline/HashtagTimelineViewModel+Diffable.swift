//
//  HashtagTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension HashtagTimelineViewModel {
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
            managedObjectContext: context.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher,
            statusTableViewCellDelegate: statusTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: timelineMiddleLoaderTableViewCellDelegate
        )
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension HashtagTimelineViewModel: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard let tableView = self.tableView else { return }
        guard let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar() else { return }
        
        guard let diffableDataSource = self.diffableDataSource else { return }
        
        let parentManagedObjectContext = fetchedResultsController.managedObjectContext
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = parentManagedObjectContext
        
        let oldSnapshot = diffableDataSource.snapshot()
        let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        
        let statusItemList: [Item] = snapshot.itemIdentifiers.map {
            let status = managedObjectContext.object(with: $0) as! Status
            
            let isStatusTextSensitive: Bool = {
                guard let spoilerText = status.spoilerText, !spoilerText.isEmpty else { return false }
                return true
            }()
            return Item.status(objectID: $0, attribute: Item.StatusAttribute(isStatusTextSensitive: isStatusTextSensitive, isStatusSensitive: status.sensitive))
        }
        
        var newSnapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
        newSnapshot.appendSections([.main])
        
        // Check if there is a `needLoadMiddleIndex`
        if let needLoadMiddleIndex = needLoadMiddleIndex, needLoadMiddleIndex < (statusItemList.count - 1) {
            // If yes, insert a `middleLoader` at the index
            var newItems = statusItemList
            newItems.insert(.homeMiddleLoader(upperTimelineIndexAnchorObjectID: snapshot.itemIdentifiers[needLoadMiddleIndex]), at: (needLoadMiddleIndex + 1))
            newSnapshot.appendItems(newItems, toSection: .main)
        } else {
            newSnapshot.appendItems(statusItemList, toSection: .main)
        }
        
        if !(self.loadoldestStateMachine.currentState is LoadOldestState.NoMore) {
            newSnapshot.appendItems([.bottomLoader], toSection: .main)
        }
        
        guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
            diffableDataSource.apply(newSnapshot)
            self.isFetchingLatestTimeline.value = false
            return
        }
        
        DispatchQueue.main.async {
            diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
                tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                tableView.contentOffset.y = tableView.contentOffset.y - difference.offset
                self.isFetchingLatestTimeline.value = false
            }
        }
    }
    
    private struct Difference<T> {
        let targetIndexPath: IndexPath
        let offset: CGFloat
    }
    
    private func calculateReloadSnapshotDifference<T: Hashable>(
        navigationBar: UINavigationBar,
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<StatusSection, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, T>
    ) -> Difference<T>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        
        let oldItemAtBeginning = oldSnapshot.itemIdentifiers(inSection: .main).first!
        
        guard let oldItemBeginIndexInNewSnapshot = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: oldItemAtBeginning) else { return nil }
        
        if oldItemBeginIndexInNewSnapshot > 0 {
            let targetIndexPath = IndexPath(row: oldItemBeginIndexInNewSnapshot, section: 0)
            let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: IndexPath(row: 0, section: 0), navigationBar: navigationBar)
            return Difference(
                targetIndexPath: targetIndexPath,
                offset: offset
            )
        }
        return nil
    }
    
}
