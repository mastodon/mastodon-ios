//
//  HomeTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/7.
//

import os.log
import UIKit
import CoreData
import CoreDataStack

extension HomeTimelineViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate,
        timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate
    ) {
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: StatusSection.Configuration(
                statusTableViewCellDelegate: statusTableViewCellDelegate,
                timelineMiddleLoaderTableViewCellDelegate: timelineMiddleLoaderTableViewCellDelegate,
                filterContext: .home,
                activeFilters: context.statusFilterService.$activeFilters
            )
        )

        // make initial snapshot animation smooth
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        fetchedResultsController.$records
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
                    var newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem> = {
                        let newItems = records.map { record in
                            StatusItem.feed(record: record)
                        }
                        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
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
                                self.fetchedResultsController.predicate,
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

                    guard let difference = await self.calculateReloadSnapshotDifference(
                        tableView: tableView,
                        oldSnapshot: oldSnapshot,
                        newSnapshot: newSnapshot
                    ) else {
                        await self.updateSnapshotUsingReloadData(snapshot: newSnapshot)
                        self.didLoadLatest.send()
                        self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                        return
                    }
                    
                    await self.updateSnapshotUsingReloadData(snapshot: newSnapshot)
                    await tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                    var contentOffset = await tableView.contentOffset
                    contentOffset.y = await tableView.contentOffset.y - difference.sourceDistanceToTableViewTopEdge
                    await tableView.setContentOffset(contentOffset, animated: false)
                    self.didLoadLatest.send()
                    self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): applied new snapshot")
                }   // end Task
            }
            .store(in: &disposeBag)
    }
    
}


extension HomeTimelineViewModel {
    
    @MainActor func updateDataSource(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>,
        animatingDifferences: Bool
    ) async {
        diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    @MainActor func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) async {
        if #available(iOS 15.0, *) {
            await self.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
        } else {
            diffableDataSource?.applySnapshot(snapshot, animated: false, completion: nil)
        }
    }
    
    struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let sourceDistanceToTableViewTopEdge: CGFloat
        let targetIndexPath: IndexPath
    }

    @MainActor private func calculateReloadSnapshotDifference<S: Hashable, T: Hashable>(
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<S, T>,
        newSnapshot: NSDiffableDataSourceSnapshot<S, T>
    ) -> Difference<T>? {
        guard let sourceIndexPath = (tableView.indexPathsForVisibleRows ?? []).sorted().first else { return nil }
        let rectForSourceItemCell = tableView.rectForRow(at: sourceIndexPath)
        let sourceDistanceToTableViewTopEdge = tableView.convert(rectForSourceItemCell, to: nil).origin.y - tableView.safeAreaInsets.top
        
        guard sourceIndexPath.section < oldSnapshot.numberOfSections,
              sourceIndexPath.row < oldSnapshot.numberOfItems(inSection: oldSnapshot.sectionIdentifiers[sourceIndexPath.section])
        else { return nil }
        
        let sectionIdentifier = oldSnapshot.sectionIdentifiers[sourceIndexPath.section]
        let item = oldSnapshot.itemIdentifiers(inSection: sectionIdentifier)[sourceIndexPath.row]
        
        guard let targetIndexPathRow = newSnapshot.indexOfItem(item),
              let newSectionIdentifier = newSnapshot.sectionIdentifier(containingItem: item),
              let targetIndexPathSection = newSnapshot.indexOfSection(newSectionIdentifier)
        else { return nil }
        
        let targetIndexPath = IndexPath(row: targetIndexPathRow, section: targetIndexPathSection)
        
        return Difference(
            item: item,
            sourceIndexPath: sourceIndexPath,
            sourceDistanceToTableViewTopEdge: sourceDistanceToTableViewTopEdge,
            targetIndexPath: targetIndexPath
        )
    }
    
}




//// MARK: - NSFetchedResultsControllerDelegate
//extension HomeTimelineViewModel: NSFetchedResultsControllerDelegate {
//
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
//        os_log("%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
//
//        guard let tableView = self.tableView else { return }
//        guard let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar() else { return }
//
//        guard let diffableDataSource = self.diffableDataSource else { return }
//        let oldSnapshot = diffableDataSource.snapshot()
//
//        let predicate = fetchedResultsController.fetchRequest.predicate
//        let parentManagedObjectContext = fetchedResultsController.managedObjectContext
//        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        managedObjectContext.parent = parentManagedObjectContext
//
//        managedObjectContext.perform {
//            var shouldAddBottomLoader = false
//
//            let timelineIndexes: [HomeTimelineIndex] = {
//                let request = HomeTimelineIndex.sortedFetchRequest
//                request.returnsObjectsAsFaults = false
//                request.predicate = predicate
//                do {
//                    return try managedObjectContext.fetch(request)
//                } catch {
//                    assertionFailure(error.localizedDescription)
//                    return []
//                }
//            }()
//
//            // that's will be the most fastest fetch because of upstream just update and no modify needs consider
//
//            var oldSnapshotAttributeDict: [NSManagedObjectID : Item.StatusAttribute] = [:]
//
//            for item in oldSnapshot.itemIdentifiers {
//                guard case let .homeTimelineIndex(objectID, attribute) = item else { continue }
//                oldSnapshotAttributeDict[objectID] = attribute
//            }
//
//            var newTimelineItems: [Item] = []
//
//            for (i, timelineIndex) in timelineIndexes.enumerated() {
//                let attribute = oldSnapshotAttributeDict[timelineIndex.objectID] ?? Item.StatusAttribute()
//                attribute.isSeparatorLineHidden = false
//
//                // append new item into snapshot
//                newTimelineItems.append(.homeTimelineIndex(objectID: timelineIndex.objectID, attribute: attribute))
//
//                let isLast = i == timelineIndexes.count - 1
//                switch (isLast, timelineIndex.hasMore) {
//                case (false, true):
//                    newTimelineItems.append(.homeMiddleLoader(upperTimelineIndexAnchorObjectID: timelineIndex.objectID))
//                    attribute.isSeparatorLineHidden = true
//                case (true, true):
//                    shouldAddBottomLoader = true
//                default:
//                    break
//                }
//            }   // end for
//
//            var newSnapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
//            newSnapshot.appendSections([.main])
//            newSnapshot.appendItems(newTimelineItems, toSection: .main)
//
//            let endSnapshot = CACurrentMediaTime()
//
//            DispatchQueue.main.async {
//                if shouldAddBottomLoader, !(self.loadLatestStateMachine.currentState is LoadOldestState.NoMore) {
//                    newSnapshot.appendItems([.bottomLoader], toSection: .main)
//                }
//
//                guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
//                    diffableDataSource.apply(newSnapshot)
//                    self.isFetchingLatestTimeline.value = false
//                    return
//                }
//
//                diffableDataSource.reloadData(snapshot: newSnapshot) {
//                    tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
//                    tableView.contentOffset.y = tableView.contentOffset.y - difference.offset
//                    self.isFetchingLatestTimeline.value = false
//                }
//
//                let end = CACurrentMediaTime()
//                os_log("%{public}s[%{public}ld], %{public}s: calculate home timeline layout cost %.2fs", ((#file as NSString).lastPathComponent), #line, #function, end - endSnapshot)
//            }
//        }   // end perform
//    }
//
//    private struct Difference<T> {
//        let item: T
//        let sourceIndexPath: IndexPath
//        let targetIndexPath: IndexPath
//        let offset: CGFloat
//    }
//
//    private func calculateReloadSnapshotDifference<T: Hashable>(
//        navigationBar: UINavigationBar,
//        tableView: UITableView,
//        oldSnapshot: NSDiffableDataSourceSnapshot<StatusSection, T>,
//        newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, T>
//    ) -> Difference<T>? {
//        guard oldSnapshot.numberOfItems != 0 else { return nil }
//
//        // old snapshot not empty. set source index path to first item if not match
//        let sourceIndexPath = UIViewController.topVisibleTableViewCellIndexPath(in: tableView, navigationBar: navigationBar) ?? IndexPath(row: 0, section: 0)
//
//        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
//
//        let timelineItem = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
//        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: timelineItem) else { return nil }
//        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
//
//        let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
//        return Difference(
//            item: timelineItem,
//            sourceIndexPath: sourceIndexPath,
//            targetIndexPath: targetIndexPath,
//            offset: offset
//        )
//    }
//
//}
