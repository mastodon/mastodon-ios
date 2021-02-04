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
                    TimelineSection.configure(cell: cell,timestampUpdatePublisher: timestampUpdatePublisher, toot: toot)
                }
                cell.delegate = timelinePostTableViewCellDelegate
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }

    static func configure(
        cell: TimelinePostTableViewCell,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        toot: Toot
    ) {
        // set name username avatar
        cell.timelinePostView.nameLabel.text = toot.author.displayName
        cell.timelinePostView.usernameLabel.text = "@" + toot.author.username
        cell.timelinePostView.avatarImageView.af.setImage(
            withURL: URL(string: toot.author.avatar)!,
            placeholderImage: UIImage.placeholder(color: .systemFill),
            imageTransition: .crossDissolve(0.2)
        )
        // set text
        cell.timelinePostView.activeTextLabel.config(content: toot.content)
        // set date
        let createdAt = (toot.reblog ?? toot).createdAt
        timestampUpdatePublisher
            .sink { _ in
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
    }
}

extension TimelineSection {
    private static func formattedNumberTitleForActionButton(_ number: Int?) -> String {
        guard let number = number, number > 0 else { return "" }
        return String(number)
    }
}
