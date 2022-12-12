//
//  DiscoveryCommunityViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-29.
//

import UIKit
import Combine

extension DiscoveryCommunityViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) {
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: StatusSection.Configuration(
                context: context,
                authContext: authContext,
                statusTableViewCellDelegate: statusTableViewCellDelegate,
                timelineMiddleLoaderTableViewCellDelegate: nil,
                filterContext: .none,
                activeFilters: nil
            )
        )
        
        stateMachine.enter(State.Reloading.self)
        
        statusFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                snapshot.appendSections([.main])
                
                let items = records.map { StatusItem.status(record: $0) }
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Initial,
                        is State.Reloading,
                        is State.Loading,
                        is State.Idle,
                        is State.Fail:
                        if !items.isEmpty {
                            snapshot.appendItems([.bottomLoader], toSection: .main)
                        }
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
