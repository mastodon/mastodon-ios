//
//  FamiliarFollowersViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit

extension FamiliarFollowersViewModel {
    func setupDiffableDataSource(
        tableView: UITableView,
        userTableViewCellDelegate: UserTableViewCellDelegate?
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: UserSection.Configuration(
                userTableViewCellDelegate: userTableViewCellDelegate
            )
        )
        
        userFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])
                let items = records.map { UserItem.user(record: $0) }
                snapshot.appendItems(items, toSection: .main)

                diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)
    }
    
}
