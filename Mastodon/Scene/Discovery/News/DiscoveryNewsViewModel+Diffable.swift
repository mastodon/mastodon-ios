//
//  DiscoveryNewsViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import Combine

extension DiscoveryNewsViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = DiscoverySection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: DiscoverySection.Configuration(authContext: authContext)
        )
        
        stateMachine.enter(State.Reloading.self)
        
        $links
            .receive(on: DispatchQueue.main)
            .sink { [weak self] links in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<DiscoverySection, DiscoveryItem>()
                snapshot.appendSections([.news])
                
                let items = links.map { DiscoveryItem.link($0) }
                snapshot.appendItems(items, toSection: .news)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Initial,
                        is State.Loading,
                        is State.Idle,
                        is State.Fail:
                        if !items.isEmpty {
                            snapshot.appendItems([.bottomLoader], toSection: .news)
                        }
                    case is State.Reloading:
                        break
                    case is State.NoMore:
                        break
                    default:
                        assertionFailure()
                        break
                    }
                }
                
                diffableDataSource.applySnapshot(snapshot, animated: false)
            }
            .store(in: &disposeBag)
    }
    
}
