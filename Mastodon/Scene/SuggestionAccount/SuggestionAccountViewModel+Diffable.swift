//
//  SuggestionAccountViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-10.
//

import UIKit

extension SuggestionAccountViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        suggestionAccountTableViewCellDelegate: SuggestionAccountTableViewCellDelegate
    ) {
        tableViewDiffableDataSource = RecommendAccountSection.tableViewDiffableDataSource(
            tableView: tableView,
            context: context,
            configuration: RecommendAccountSection.Configuration(
                authContext: authContext,
                suggestionAccountTableViewCellDelegate: suggestionAccountTableViewCellDelegate
            )
        )

        userFetchedResultsController.$records
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let tableViewDiffableDataSource = self.tableViewDiffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<RecommendAccountSection, RecommendAccountItem>()
                snapshot.appendSections([.main])
                let items: [RecommendAccountItem] = records.map { RecommendAccountItem.account($0) }
                snapshot.appendItems(items, toSection: .main)
                
                if #available(iOS 15.0, *) {
                    tableViewDiffableDataSource.applySnapshotUsingReloadData(snapshot, completion: nil)
                } else {
                    // Fallback on earlier versions
                    tableViewDiffableDataSource.applySnapshot(snapshot, animated: false, completion: nil)
                }
            }
            .store(in: &disposeBag)
    }
    
    func setupDiffableDataSource(
        collectionView: UICollectionView
    ) {
        collectionViewDiffableDataSource = SelectedAccountSection.collectionViewDiffableDataSource(
            collectionView: collectionView,
            context: context
        )
        
        selectedUserFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let collectionViewDiffableDataSource = self.collectionViewDiffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<SelectedAccountSection, SelectedAccountItem>()
                snapshot.appendSections([.main])
                var items: [SelectedAccountItem] = records.map { SelectedAccountItem.account($0) }
                
                if items.count < 10 {
                    let count = 10 - items.count
                    let placeholderItems: [SelectedAccountItem] = (0..<count).map { _ in
                        SelectedAccountItem.placeHolder(uuid: UUID())
                    }
                    items.append(contentsOf: placeholderItems)
                }
                
                snapshot.appendItems(items, toSection: .main)
                
                if #available(iOS 15.0, *) {
                    collectionViewDiffableDataSource.applySnapshotUsingReloadData(snapshot, completion: nil)
                } else {
                    // Fallback on earlier versions
                    collectionViewDiffableDataSource.applySnapshot(snapshot, animated: false, completion: nil)
                }
            }
            .store(in: &disposeBag)
    }
    
}
