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
        authenticationBox: MastodonAuthenticationBox,
        userTableViewCellDelegate: UserTableViewCellDelegate?
    ) -> UITableViewDiffableDataSource<UserSection, UserItem> {
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TimelineFooterTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineFooterTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) {
            tableView,
            indexPath,
            item -> UITableViewCell? in
            switch item {
                case .account(let account, let relationship):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as? UserTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }

                    guard let me = authenticationBox.cachedAccount else { return cell }

                    cell.userView.setButtonState(.loading)
                    cell.configure(
                        me: me,
                        tableView: tableView,
                        account: account,
                        relationship: relationship,
                        delegate: userTableViewCellDelegate
                    )

                    return cell
                case .bottomLoader:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as? TimelineBottomLoaderTableViewCell else { assertionFailure("unexpected cell dequeued")
                    return nil
                }
                    cell.startAnimating()
                    return cell
                case .bottomHeader(let text):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineFooterTableViewCell.self), for: indexPath) as? TimelineFooterTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                    cell.messageLabel.text = text
                    return cell
            }
        }
    }
}
