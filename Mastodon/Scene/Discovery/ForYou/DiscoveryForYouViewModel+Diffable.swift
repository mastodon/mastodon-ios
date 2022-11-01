//
//  DiscoveryForYouViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-14.
//

import UIKit
import Combine
import MastodonUI

extension DiscoveryForYouViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        profileCardTableViewCellDelegate: ProfileCardTableViewCellDelegate
    ) {
        diffableDataSource = DiscoverySection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: DiscoverySection.Configuration(
                authContext: authContext,
                profileCardTableViewCellDelegate: profileCardTableViewCellDelegate,
                familiarFollowers: $familiarFollowers
            )
        )
        
        Task {
            try await fetch()
        }
        
        userFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<DiscoverySection, DiscoveryItem>()
                snapshot.appendSections([.forYou])
                
                let items = records.map { DiscoveryItem.user($0) }
                snapshot.appendItems(items, toSection: .forYou)
            
                diffableDataSource.applySnapshot(snapshot, animated: false)
            }
            .store(in: &disposeBag)
    }
    
}
