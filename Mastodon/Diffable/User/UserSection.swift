//
//  UserSection.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import UIKit
import CoreData
import CoreDataStack
import MastodonCore
import MastodonUI
import MastodonMeta
import MetaTextKit
import Combine

enum UserSection: Hashable {
    case main
}

extension UserSection {
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        authContext: AuthContext,
        userTableViewCellDelegate: UserTableViewCellDelegate?
    ) -> UITableViewDiffableDataSource<UserSection, UserItem> {
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TimelineFooterTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineFooterTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
                case .account(let account):
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
                    cell.configure(tableView: tableView, account: account, delegate: userTableViewCellDelegate)
                    cell.userView.setButtonState(.loading)
                    Task {
                        do {

                            guard let relationship = try await context.apiService.relationship(forAccounts: [account], authenticationBox: authContext.mastodonAuthenticationBox).value.first else {
                                return await MainActor.run {
                                    cell.userView.setButtonState(.none)
                                }
                            }

                            let buttonState: UserView.ButtonState
                            if relationship.following {
                                buttonState = .unfollow
                            } else if relationship.blocking || (relationship.domainBlocking ?? false) {
                                buttonState = .blocked
                            } else if relationship.requested ?? false {
                                buttonState = .pending
                            } else {
                                buttonState = .follow
                            }

                            await MainActor.run {
                                cell.userView.setButtonState(buttonState)
                            }
                        } catch {
                            await MainActor.run {
                                cell.userView.setButtonState(.none)
                            }
                        }
                    }

                    return cell

                case .user(let record):
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
                    context.managedObjectContext.performAndWait {
                        guard let user = record.object(in: context.managedObjectContext) else { return }
                        configure(
                            context: context,
                            authContext: authContext,
                            tableView: tableView,
                            cell: cell,
                            viewModel: UserTableViewCell.ViewModel(
                                user: user,
                                followedUsers: authContext.mastodonAuthenticationBox.inMemoryCache.$followingUserIds.eraseToAnyPublisher(),
                                blockedUsers: authContext.mastodonAuthenticationBox.inMemoryCache.$blockedUserIds.eraseToAnyPublisher(),
                                followRequestedUsers: authContext.mastodonAuthenticationBox.inMemoryCache.$followRequestedUserIDs.eraseToAnyPublisher()
                            ),
                            userTableViewCellDelegate: userTableViewCellDelegate
                        )
                    }

                    return cell
                case .bottomLoader:
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                    cell.startAnimating()
                    return cell
                case .bottomHeader(let text):
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineFooterTableViewCell.self), for: indexPath) as! TimelineFooterTableViewCell
                    cell.messageLabel.text = text
                    return cell
            }
        }
    }
}

extension UserSection {

    static func configure(
        context: AppContext,
        authContext: AuthContext,
        tableView: UITableView,
        cell: UserTableViewCell,
        viewModel: UserTableViewCell.ViewModel,
        userTableViewCellDelegate: UserTableViewCellDelegate?
    ) {
        cell.configure(
            me: authContext.mastodonAuthenticationBox.authentication.user(in: context.managedObjectContext),
            tableView: tableView,
            viewModel: viewModel,
            delegate: userTableViewCellDelegate
        )
    }

}
