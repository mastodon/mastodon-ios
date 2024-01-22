//
//  UserListViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import MastodonAsset
import MastodonLocalization
import Combine
import MastodonSDK

extension UserListViewModel {
    @MainActor
    func setupDiffableDataSource(
        tableView: UITableView,
        userTableViewCellDelegate: UserTableViewCellDelegate?
    ) {
        diffableDataSource = UserSection.diffableDataSource(
            tableView: tableView,
            context: context,
            authContext: authContext,
            userTableViewCellDelegate: userTableViewCellDelegate
        )
        
        // workaround to append loader wrong animation issue
        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.bottomLoader], toSection: .main)
        diffableDataSource?.applySnapshotUsingReloadData(snapshot)

        // trigger initial loading
        stateMachine.enter(UserListViewModel.State.Reloading.self)
        
        $accounts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] accounts in
                guard let self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
            
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])

                let accountsWithRelationship: [(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)] = accounts.compactMap { account in
                    guard let relationship = self.relationships.first(where: {$0.id == account.id }) else { return (account: account, relationship: nil)}

                    return (account: account, relationship: relationship)
                }

                let items = accountsWithRelationship.map { UserItem.account(account: $0.account, relationship: $0.relationship) }
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
