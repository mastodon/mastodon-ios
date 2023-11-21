//
//  FamiliarFollowersViewModel.swift
//  Mastodon
//
//  Created by MainasuK on 2022-5-17.
//

import UIKit
import MastodonCore
import MastodonSDK

final class FamiliarFollowersViewModel {
    let context: AppContext
    let authContext: AuthContext

    var accounts: [Mastodon.Entity.Account]
    var relationships: [Mastodon.Entity.Relationship]

    // output
    var diffableDataSource: UITableViewDiffableDataSource<UserSection, UserItem>?

    init(context: AppContext, authContext: AuthContext, accounts: [Mastodon.Entity.Account], relationships: [Mastodon.Entity.Relationship]) {
        self.context = context
        self.authContext = authContext
        self.accounts = accounts
        self.relationships = relationships
    }

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
    }

    func viewWillAppear() {
        guard let diffableDataSource else { return }

        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        let accountsWithRelationship: [(account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)] = accounts.compactMap { account in
            guard let relationship = self.relationships.first(where: {$0.id == account.id }) else { return (account: account, relationship: nil)}

            return (account: account, relationship: relationship)
        }

        let items = accountsWithRelationship.map { UserItem.account(account: $0.account, relationship: $0.relationship) }

        snapshot.appendItems(items, toSection: .main)

        diffableDataSource.apply(snapshot, animatingDifferences: false)

    }
}
