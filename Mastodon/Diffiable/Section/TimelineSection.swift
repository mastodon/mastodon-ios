//
//  TimelineSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import Combine
import CoreData
import CoreDataStack
import os.log
import UIKit

enum TimelineSection: Equatable, Hashable {
    case main
}

extension TimelineSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        managedObjectContext: NSManagedObjectContext,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<TimelineSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak timelinePostTableViewCellDelegate] tableView, indexPath, item -> UITableViewCell? in
            guard let timelinePostTableViewCellDelegate = timelinePostTableViewCellDelegate else { return UITableViewCell() }

            switch item {
            case .toot(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell

                // configure cell
                managedObjectContext.performAndWait {
                    let toot = managedObjectContext.object(with: objectID) as! Toot
                    TimelineSection.configure(cell: cell, toot: toot)
                }
                cell.delegate = timelinePostTableViewCellDelegate
                return cell
            }
        }
    }

    static func configure(
        cell: TimelinePostTableViewCell,
        toot: Toot
    ) {
        cell.timelinePostView.nameLabel.text = toot.author.displayName
        cell.timelinePostView.usernameLabel.text =  toot.author.username
        cell.timelinePostView.avatarImageView.af.setImage(withURL: URL(string: toot.author.avatar)!)
        cell.timelinePostView.activeTextLabel.config(content: toot.content)
    }
}

extension TimelineSection {
    private static func formattedNumberTitleForActionButton(_ number: Int?) -> String {
        guard let number = number, number > 0 else { return "" }
        return String(number)
    }
}
