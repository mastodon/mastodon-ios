//
//  DiscoveryHashtagsViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit

extension DiscoveryHashtagsViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = DiscoverySection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: DiscoverySection.Configuration(authContext: authContext)
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<DiscoverySection, DiscoveryItem>()
        snapshot.appendSections([.hashtags])
        diffableDataSource?.apply(snapshot)
        
        $hashtags
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hashtags in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<DiscoverySection, DiscoveryItem>()
                snapshot.appendSections([.hashtags])
                
                let items = hashtags.map { DiscoveryItem.hashtag($0) }
                snapshot.appendItems(items.removingDuplicates(), toSection: .hashtags)
                
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
    
}
