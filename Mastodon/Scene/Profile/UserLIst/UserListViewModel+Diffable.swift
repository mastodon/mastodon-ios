//
//  UserListViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import MastodonAsset
import MastodonLocalization

extension UserListViewModel {
    @MainActor
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
        
        // workaround to append loader wrong animation issue
        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.bottomLoader], toSection: .main)
        if #available(iOS 15.0, *) {
            diffableDataSource?.applySnapshotUsingReloadData(snapshot, completion: nil)
        } else {
            // Fallback on earlier versions
            diffableDataSource?.apply(snapshot, animatingDifferences: false)
        }
        
        // trigger initial loading
        stateMachine.enter(UserListViewModel.State.Reloading.self)
        
        userFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
            
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])
                let items = records.map { UserItem.user(record: $0) }
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Initial, is State.Idle, is State.Reloading, is State.Loading, is State.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    case is State.NoMore:
                        if items.isEmpty {
                            snapshot.appendItems([.bottomHeader(text: L10n.Scene.Search.Searching.EmptyState.noResults)], toSection: .main)
                        }
                    default:
                        assertionFailure()
                    }
                } else {
                    snapshot.appendItems([.bottomLoader], toSection: .main)
                }
                
                diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)
    }
}
