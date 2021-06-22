//
//  NotificationSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit

enum NotificationSection: Equatable, Hashable {
    case main
}

extension NotificationSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        managedObjectContext: NSManagedObjectContext,
        delegate: NotificationTableViewCellDelegate,
        dependency: NeedsDependency
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {
        UITableViewDiffableDataSource(tableView: tableView) {
            [weak delegate, weak dependency]
            (tableView, indexPath, notificationItem) -> UITableViewCell? in
            guard let dependency = dependency else { return nil }
            switch notificationItem {
            case .notification(let objectID, let attribute):
                let notification = managedObjectContext.object(with: objectID) as! MastodonNotification
                guard let type = Mastodon.Entity.Notification.NotificationType(rawValue: notification.typeRaw) else {
                    // filter out invalid type using predicate
                    assertionFailure()
                    return UITableViewCell()
                }
                
                let createAt = notification.createAt
                let timeText = createAt.timeAgoSinceNow
                
                let actionText = type.actionText
                let actionImageName = type.actionImageName
                let color = type.color
                
                if let status = notification.status {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationStatusTableViewCell.self), for: indexPath) as! NotificationStatusTableViewCell
                    cell.delegate = delegate
                    let activeMastodonAuthenticationBox = dependency.context.authenticationService.activeMastodonAuthenticationBox.value
                    let requestUserID = activeMastodonAuthenticationBox?.userID ?? ""
                    let frame = CGRect(x: 0, y: 0, width: tableView.readableContentGuide.layoutFrame.width - NotificationStatusTableViewCell.statusPadding.left - NotificationStatusTableViewCell.statusPadding.right, height: tableView.readableContentGuide.layoutFrame.height)
                    StatusSection.configure(
                        cell: cell,
                        dependency: dependency,
                        readableLayoutFrame: frame,
                        timestampUpdatePublisher: timestampUpdatePublisher,
                        status: status,
                        requestUserID: requestUserID,
                        statusItemAttribute: attribute
                    )
                    cell.actionImageBackground.backgroundColor = color
                    cell.nameLabel.text = notification.account.displayName.isEmpty ? notification.account.username : notification.account.displayName
                    cell.actionLabel.text = actionText + " · " + timeText
                    timestampUpdatePublisher
                        .sink { [weak cell] _ in
                            guard let cell = cell else { return }
                            let timeText = createAt.slowedTimeAgoSinceNow
                            cell.actionLabel.text = actionText + " · " + timeText
                        }
                        .store(in: &cell.disposeBag)
                    if let url = notification.account.avatarImageURL() {
                        cell.avatarImageView.af.setImage(
                            withURL: url,
                            placeholderImage: UIImage.placeholder(color: .systemFill),
                            imageTransition: .crossDissolve(0.2)
                        )
                    }
                    cell.avatarImageView.gesture().sink { [weak cell] _ in
                        cell?.delegate?.userAvatarDidPressed(notification: notification)
                    }
                    .store(in: &cell.disposeBag)
                    if let actionImage = UIImage(systemName: actionImageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))?.withRenderingMode(.alwaysTemplate) {
                        cell.actionImageView.image = actionImage
                    }
                    return cell
                    
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as! NotificationTableViewCell
                    cell.delegate = delegate
                    timestampUpdatePublisher
                        .sink { [weak cell] _ in
                            guard let cell = cell else { return }
                            let timeText = createAt.slowedTimeAgoSinceNow
                            cell.actionLabel.text = actionText + " · " + timeText
                        }
                        .store(in: &cell.disposeBag)
                    cell.acceptButton.publisher(for: .touchUpInside)
                        .sink { [weak cell] _ in
                            guard let cell = cell else { return }
                            cell.delegate?.notificationTableViewCell(cell, notification: notification, acceptButtonDidPressed: cell.acceptButton)
                        }
                        .store(in: &cell.disposeBag)
                    cell.rejectButton.publisher(for: .touchUpInside)
                        .sink { [weak cell] _ in
                            guard let cell = cell else { return }
                            cell.delegate?.notificationTableViewCell(cell, notification: notification, rejectButtonDidPressed: cell.rejectButton)
                        }
                        .store(in: &cell.disposeBag)
                    cell.actionImageBackground.backgroundColor = color
                    cell.actionLabel.text = actionText + " · " + timeText
                    cell.nameLabel.text = notification.account.displayName.isEmpty ? notification.account.username : notification.account.displayName
                    if let url = notification.account.avatarImageURL() {
                        cell.avatatImageView.af.setImage(
                            withURL: url,
                            placeholderImage: UIImage.placeholder(color: .systemFill),
                            imageTransition: .crossDissolve(0.2)
                        )
                    }
                    cell.avatatImageView.gesture().sink { [weak cell] _ in
                        cell?.delegate?.userAvatarDidPressed(notification: notification)
                    }
                    .store(in: &cell.disposeBag)
                    if let actionImage = UIImage(systemName: actionImageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))?.withRenderingMode(.alwaysTemplate) {
                        cell.actionImageView.image = actionImage
                    }
                    cell.buttonStackView.isHidden = (type != .followRequest)
                    return cell
                }
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self)) as! TimelineBottomLoaderTableViewCell
                cell.startAnimating()
                return cell
            }
        }
    }
}

