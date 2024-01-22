//
//  FollowingListViewModel+Diffable.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-2.
//

import UIKit
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonSDK

extension FollowingListViewModel {
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
                        case is State.Loading:
                            snapshot.appendItems([.bottomLoader], toSection: .main)
                        case is State.NoMore:
                            guard let userID = self.userID,
                                  userID != self.authContext.mastodonAuthenticationBox.userID
                            else { break }
                            // display footer exclude self
                            let text = L10n.Scene.Following.footer
                            snapshot.appendItems([.bottomHeader(text: text)], toSection: .main)
                        case is State.Idle, is State.Fail:
                            break
                        default:
                            break
                    }
                }

                diffableDataSource.apply(snapshot, animatingDifferences: false)
            }
            .store(in: &disposeBag)
    }
}
