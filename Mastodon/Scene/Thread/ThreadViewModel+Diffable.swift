//
//  ThreadViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-12.
//

import UIKit
import Combine
import CoreData

extension ThreadViewModel {
    
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        statusTableViewCellDelegate: StatusTableViewCellDelegate,
        threadReplyLoaderTableViewCellDelegate: ThreadReplyLoaderTableViewCellDelegate
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
            timelineMiddleLoaderTableViewCellDelegate: nil,
            threadReplyLoaderTableViewCellDelegate: threadReplyLoaderTableViewCellDelegate
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
        snapshot.appendSections([.main])
        if let rootNode = self.rootNode.value, rootNode.replyToID != nil {
            snapshot.appendItems([.topLoader], toSection: .main)
        }
        
        diffableDataSource?.apply(snapshot, animatingDifferences: false, completion: nil)
        
        Publishers.CombineLatest3(
            rootItem,
            ancestorItems,
            descendantItems
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)       // some magic to avoid jitter
        .receive(on: DispatchQueue.main)
        .sink { [weak self] rootItem, ancestorItems, descendantItems in
            guard let self = self else { return }
            guard let tableView = self.tableView,
                  let navigationBar = self.contentOffsetAdjustableTimelineViewControllerDelegate?.navigationBar()
            else { return }
            
            guard let diffableDataSource = self.diffableDataSource else { return }
            let oldSnapshot = diffableDataSource.snapshot()
            
            var newSnapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
            newSnapshot.appendSections([.main])
            
            let currentState = self.loadThreadStateMachine.currentState
            
            // reply to
            if self.rootNode.value?.replyToID != nil, !(currentState is LoadThreadState.NoMore) {
                newSnapshot.appendItems([.topLoader], toSection: .main)
            }
            newSnapshot.appendItems(ancestorItems, toSection: .main)
            
            // root
            if let rootItem = rootItem {
                switch rootItem {
                case .root:
                    newSnapshot.appendItems([rootItem], toSection: .main)
                default:
                    break
                }
            }
            
            // leaf
            if !(currentState is LoadThreadState.NoMore) {
                newSnapshot.appendItems([.bottomLoader], toSection: .main)
            }
            newSnapshot.appendItems(descendantItems, toSection: .main)
            
            // difference for first visiable item exclude .topLoader
            guard let difference = self.calculateReloadSnapshotDifference(navigationBar: navigationBar, tableView: tableView, oldSnapshot: oldSnapshot, newSnapshot: newSnapshot) else {
                diffableDataSource.apply(newSnapshot)
                return
            }

            // addtional margin for .topLoader
            let oldTopMargin: CGFloat = {
                let marginHeight = TimelineTopLoaderTableViewCell.cellHeight
                if oldSnapshot.itemIdentifiers.contains(.topLoader) {
                    return marginHeight
                }
                if !ancestorItems.isEmpty {
                    return marginHeight
                }
                
                return .zero
            }()
            
            let oldRootCell: UITableViewCell? = {
                guard let rootItem = rootItem else { return nil }
                guard let index = oldSnapshot.indexOfItem(rootItem) else { return nil }
                guard let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) else { return nil }
                return cell
            }()
            // save height before cell reuse
            let oldRootCellHeight = oldRootCell?.frame.height
            
            diffableDataSource.apply(newSnapshot, animatingDifferences: false) {
                guard let _ = rootItem else {
                    return
                }
                if let oldRootCellHeight = oldRootCellHeight {
                    // set bottom inset. Make root item pin to top (with margin).
                    let bottomSpacing = tableView.safeAreaLayoutGuide.layoutFrame.height - oldRootCellHeight - oldTopMargin
                    tableView.contentInset.bottom = max(0, bottomSpacing)
                }

                // set scroll position
                tableView.scrollToRow(at: difference.targetIndexPath, at: .top, animated: false)
                let contentOffsetY: CGFloat = {
                    var offset: CGFloat = tableView.contentOffset.y - difference.offset
                    if tableView.contentInset.bottom != 0.0 && descendantItems.isEmpty {
                        // needs restore top margin if bottom inset adjusted AND no descendantItems
                        offset += oldTopMargin
                    }
                    return offset
                }()
                tableView.setContentOffset(CGPoint(x: 0, y: contentOffsetY), animated: false)
            }
        }
        .store(in: &disposeBag)
    }
    
}

extension ThreadViewModel {
    private struct Difference<T> {
        let item: T
        let sourceIndexPath: IndexPath
        let targetIndexPath: IndexPath
        let offset: CGFloat
    }
    
    private func calculateReloadSnapshotDifference(
        navigationBar: UINavigationBar,
        tableView: UITableView,
        oldSnapshot: NSDiffableDataSourceSnapshot<StatusSection, Item>,
        newSnapshot: NSDiffableDataSourceSnapshot<StatusSection, Item>
    ) -> Difference<Item>? {
        guard oldSnapshot.numberOfItems != 0 else { return nil }
        guard let visibleIndexPaths = tableView.indexPathsForVisibleRows?.sorted() else { return nil }
    
        // find index of the first visible item exclude .topLoader
        var _index: Int?
        let items = oldSnapshot.itemIdentifiers(inSection: .main)
        for (i, item) in items.enumerated() {
            if case .topLoader = item { continue }
            guard visibleIndexPaths.contains(where: { $0.row == i }) else { continue }
            
            _index = i
            break
        }
        
        guard let index = _index else  { return nil }
        let sourceIndexPath = IndexPath(row: index, section: 0)
        guard sourceIndexPath.row < oldSnapshot.itemIdentifiers(inSection: .main).count else { return nil }
        
        let item = oldSnapshot.itemIdentifiers(inSection: .main)[sourceIndexPath.row]
        guard let itemIndex = newSnapshot.itemIdentifiers(inSection: .main).firstIndex(of: item) else { return nil }
        let targetIndexPath = IndexPath(row: itemIndex, section: 0)
        
        let offset = UIViewController.tableViewCellOriginOffsetToWindowTop(in: tableView, at: sourceIndexPath, navigationBar: navigationBar)
        return Difference(
            item: item,
            sourceIndexPath: sourceIndexPath,
            targetIndexPath: targetIndexPath,
            offset: offset
        )
    }
}
