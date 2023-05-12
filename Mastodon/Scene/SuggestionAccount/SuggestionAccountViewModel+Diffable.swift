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
                
                tableViewDiffableDataSource.applySnapshotUsingReloadData(snapshot, completion: nil)
            }
            .store(in: &disposeBag)
    }
}
