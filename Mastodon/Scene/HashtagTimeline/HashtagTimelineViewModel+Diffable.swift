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
            timelineContext: .hashtag,
            dependency: dependency,
            managedObjectContext: context.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher,
            statusTableViewCellDelegate: statusTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: timelineMiddleLoaderTableViewCellDelegate,
            threadReplyLoaderTableViewCellDelegate: nil
        )

        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)

        // workaround to append loader wrong animation issue
        snapshot.appendItems([.bottomLoader], toSection: .main)
        diffableDataSource?.apply(snapshot)
    }
}

// MARK: - Compare old & new snapshots and generate new items
extension HashtagTimelineViewModel {
    func generateStatusItems(newObjectIDs: [NSManagedObjectID]) {
        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard let tableView = self.tableView else { return }
        guard let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar() else { return }
        
        guard let diffableDataSource = self.diffableDataSource else { return }
        
        let parentManagedObjectContext = fetchedResultsController.fetchedResultsController.managedObjectContext
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.parent = parentManagedObjectContext
        
        let oldSnapshot = diffableDataSource.snapshot()
//        let snapshot = snapshot as NSDiffableDataSourceSnapshot<Int, NSManagedObjectID>
        
        var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
        for item in oldSnapshot.itemIdentifiers {
            guard case let .status(objectID, attribute) = item else { continue }
            oldSnapshotAttributeDict[objectID] = attribute
        }
        
        let statusItemList: [Item] = newObjectIDs.map {
            let attribute = oldSnapshotAttributeDict[$0] ?? Item.StatusAttribute()
            return Item.status(objectID: $0, attribute: attribute)
        }
        
        var newSnapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
        newSnapshot.appendSections([.main])
        
        // Check if there is a `needLoadMiddleIndex`
        if let needLoadMiddleIndex = needLoadMiddleIndex, needLoadMiddleIndex < (statusItemList.count - 1) {
            // If yes, insert a `middleLoader` at the index
            var newItems = statusItemList
            newItems.insert(.homeMiddleLoader(upperTimelineIndexAnchorObjectID: newObjectIDs[needLoadMiddleIndex]), at: (needLoadMiddleIndex + 1))
            newSnapshot.appendItems(newItems, toSection: .main)
        } else {
            newSnapshot.appendItems(statusItemList, toSection: .main)
        }
        
        if !(self.loadOldestStateMachine.currentState is LoadOldestState.NoMore) {
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
        guard let item = oldSnapshot.itemIdentifiers.first as? Item, case Item.status = item else { return nil }
        
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
