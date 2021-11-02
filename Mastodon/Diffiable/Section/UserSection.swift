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
import MetaTextKit
import MastodonMeta

enum UserSection: Hashable {
    case main
}

extension UserSection {
    
    static let logger = Logger(subsystem: "StatusSection", category: "logic")

    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        managedObjectContext: NSManagedObjectContext
    ) -> UITableViewDiffableDataSource<UserSection, UserItem> {
        UITableViewDiffableDataSource(tableView: tableView) { [
            weak dependency
        ] tableView, indexPath, item -> UITableViewCell? in
            guard let dependency = dependency else { return UITableViewCell() }
            switch item {
            case .follower(let objectID),
                 .following(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
                managedObjectContext.performAndWait {
                    let user = managedObjectContext.object(with: objectID) as! MastodonUser
                    configure(cell: cell, user: user)
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
        cell: UserTableViewCell,
        user: MastodonUser
    ) {
        cell.configure(user: user)
    }

}
