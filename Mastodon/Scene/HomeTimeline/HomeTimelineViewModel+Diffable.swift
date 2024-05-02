//
//  HomeTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/2/7.
//

import UIKit
import MastodonUI
import MastodonSDK

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
                context: context,
                authContext: authContext,
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
        
        dataController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                guard let currentState = loadLatestStateMachine.currentState as? HomeTimelineViewModel.LoadLatestState,
                      (currentState.self is HomeTimelineViewModel.LoadLatestState.ContextSwitch) == false else { return }

                Task { @MainActor in
                    let oldSnapshot = diffableDataSource.snapshot()
                    var newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem> = {
                        let newItems = records.map { record in
                            StatusItem.feed(record: record)
                        }.removingDuplicates()
                        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                        snapshot.appendSections([.main])
                        snapshot.appendItems(newItems, toSection: .main)
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
                    if !hasChanges && !self.hasPendingStatusEditReload {
                        self.didLoadLatest.send()
                        return
                    }

                    guard let difference = self.calculateReloadSnapshotDifference(
                        tableView: tableView,
                        oldSnapshot: oldSnapshot,
                        newSnapshot: newSnapshot
                    ) else {
                        await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                        self.didLoadLatest.send()
                        return
                    }
                    
                    await self.updateDataSource(snapshot: newSnapshot, animatingDifferences: false)
                    if tableView.numberOfSections >= difference.targetIndexPath.section && tableView.numberOfRows(inSection: difference.targetIndexPath.section) >= difference.targetIndexPath.row {
                        tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                    }
                    var contentOffset = tableView.contentOffset
                    contentOffset.y = tableView.contentOffset.y - difference.sourceDistanceToTableViewTopEdge
                    tableView.setContentOffset(contentOffset, animated: false)
                    self.didLoadLatest.send()
                    self.hasPendingStatusEditReload = false
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
        await diffableDataSource?.apply(snapshot, animatingDifferences: animatingDifferences)
    }
    
    @MainActor func updateSnapshotUsingReloadData(
        snapshot: NSDiffableDataSourceSnapshot<StatusSection, StatusItem>
    ) {
        self.diffableDataSource?.applySnapshotUsingReloadData(snapshot)
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
        let sourceDistanceToTableViewTopEdge: CGFloat = {
            if tableView.window != nil {
                return tableView.convert(rectForSourceItemCell, to: nil).origin.y - tableView.safeAreaInsets.top
            } else {
                return rectForSourceItemCell.origin.y - tableView.contentOffset.y - tableView.safeAreaInsets.top
            }
        }()

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
