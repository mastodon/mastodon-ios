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
        timelinePostTableViewCellDelegate: TimelinePostTableViewCellDelegate,
        timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
    ) -> UITableViewDiffableDataSource<TimelineSection, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak timelinePostTableViewCellDelegate, weak timelineMiddleLoaderTableViewCellDelegate] tableView, indexPath, item -> UITableViewCell? in
            guard let timelinePostTableViewCellDelegate = timelinePostTableViewCellDelegate else { return UITableViewCell() }

            switch item {
            case .homeTimelineIndex(objectID: let objectID, attribute: _):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell

                // configure cell
                managedObjectContext.performAndWait {
                    let timelineIndex = managedObjectContext.object(with: objectID) as! HomeTimelineIndex
                    TimelineSection.configure(cell: cell, timestampUpdatePublisher: timestampUpdatePublisher, toot: timelineIndex.toot, requestUserID: timelineIndex.userID)
                }
                cell.delegate = timelinePostTableViewCellDelegate
                return cell
            case .toot(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelinePostTableViewCell.self), for: indexPath) as! TimelinePostTableViewCell
                let activeMastodonAuthenticationBox = dependency.context.authenticationService.activeMastodonAuthenticationBox.value
                let requestUserID = activeMastodonAuthenticationBox?.userID ?? ""
                // configure cell
                managedObjectContext.performAndWait {
                    let toot = managedObjectContext.object(with: objectID) as! Toot
                    TimelineSection.configure(cell: cell, timestampUpdatePublisher: timestampUpdatePublisher, toot: toot, requestUserID:requestUserID)
                }
                cell.delegate = timelinePostTableViewCellDelegate
                return cell
            case .publicMiddleLoader(let upperTimelineTootID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                cell.delegate = timelineMiddleLoaderTableViewCellDelegate
                timelineMiddleLoaderTableViewCellDelegate?.configure(cell: cell, upperTimelineTootID: upperTimelineTootID,timelineIndexobjectID: nil)
                return cell
            case .homeMiddleLoader(let upperTimelineIndexObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                cell.delegate = timelineMiddleLoaderTableViewCellDelegate
                timelineMiddleLoaderTableViewCellDelegate?.configure(cell: cell, upperTimelineTootID: nil,timelineIndexobjectID: upperTimelineIndexObjectID)
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
        toot: Toot,
        requestUserID: String
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
        
        // toolbar
        let isLike = (toot.reblog ?? toot).favouritedBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
        let favoriteCountTitle: String = {
            let count = (toot.reblog ?? toot).favouritesCount.intValue
            return TimelineSection.formattedNumberTitleForActionButton(count)
        }()
        cell.timelinePostView.actionToolbarContainer.starButton.setTitle(favoriteCountTitle, for: .normal)
        cell.timelinePostView.actionToolbarContainer.isStarButtonHighlight = isLike
        // set date
        let createdAt = (toot.reblog ?? toot).createdAt
        timestampUpdatePublisher
            .sink { _ in
                cell.timelinePostView.dateLabel.text = createdAt.shortTimeAgoSinceNow
            }
            .store(in: &cell.disposeBag)
        
        // observe model change
        ManagedObjectObserver.observe(object: toot.reblog ?? toot)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // do nothing
            } receiveValue: { change in
                guard case let .update(object) = change.changeType,
                      let newToot = object as? Toot else { return }
                let targetToot = newToot.reblog ?? newToot
                
                let isLike = targetToot.favouritedBy.flatMap({ $0.contains(where: { $0.id == requestUserID }) }) ?? false
                let favoriteCount = targetToot.favouritesCount.intValue
                let favoriteCountTitle = TimelineSection.formattedNumberTitleForActionButton(favoriteCount)
                cell.timelinePostView.actionToolbarContainer.starButton.setTitle(favoriteCountTitle, for: .normal)
                cell.timelinePostView.actionToolbarContainer.isStarButtonHighlight = isLike
                os_log("%{public}s[%{public}ld], %{public}s: like count label for tweet %s did update: %ld", ((#file as NSString).lastPathComponent), #line, #function, targetToot.id, favoriteCount )
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
