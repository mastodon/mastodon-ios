//
//  UserSection.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import os.log
import UIKit
import CoreData
import CoreDataStack
import MastodonCore
import MastodonUI
import MastodonMeta
import MetaTextKit

enum UserSection: Hashable {
    case main
}

extension UserSection {
    
    static let logger = Logger(subsystem: "StatusSection", category: "logic")
    
    struct Configuration {
        weak var userTableViewCellDelegate: UserTableViewCellDelegate?
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<UserSection, UserItem> {
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(TimelineFooterTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineFooterTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .user(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let user = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        tableView: tableView,
                        cell: cell,
                        viewModel: .init(value: .user(user)),
                        configuration: configuration
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
            }   // end switch
        }   // end UITableViewDiffableDataSource
    }   // end static func tableViewDiffableDataSource { … }
    
}

extension UserSection {

    static func configure(
        tableView: UITableView,
        cell: UserTableViewCell,
        viewModel: UserTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.userTableViewCellDelegate
        )
    }

}
