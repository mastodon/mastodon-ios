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
import Nuke

enum NotificationSection: Equatable, Hashable {
    case main
}

extension NotificationSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
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
                guard let notification = try? managedObjectContext.existingObject(with: objectID) as? MastodonNotification,
                      !notification.isDeleted else {
                    return UITableViewCell()
                }

                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationStatusTableViewCell.self), for: indexPath) as! NotificationStatusTableViewCell
                cell.delegate = delegate

                // configure author
                cell.configure(
                    with: AvatarConfigurableViewConfiguration(
                        avatarImageURL: notification.account.avatarImageURL()
                    )
                )
                cell.actionImageView.image = UIImage(
                    systemName: notification.notificationType.actionImageName,
                    withConfiguration: UIImage.SymbolConfiguration(
                        pointSize: 12, weight: .semibold
                    )
                )?
                .withRenderingMode(.alwaysTemplate)
                .af.imageAspectScaled(toFit: CGSize(width: 14, height: 14))

                cell.actionImageView.backgroundColor = notification.notificationType.color

                // configure author name, notification description, timestamp
                cell.nameLabel.configure(content: notification.account.displayNameWithFallback, emojiDict: notification.account.emojiDict)
                let createAt = notification.createAt
                let actionText = notification.notificationType.actionText
                cell.actionLabel.text = actionText + " · " + createAt.timeAgoSinceNow
                AppContext.shared.timestampUpdatePublisher
                    .receive(on: DispatchQueue.main)
                    .sink { [weak cell] _ in
                        guard let cell = cell else { return }
                        cell.actionLabel.text = actionText + " · " + createAt.timeAgoSinceNow
                    }
                    .store(in: &cell.disposeBag)

                // configure follow request (if exist)
                if case .followRequest = notification.notificationType {
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
                    cell.buttonStackView.isHidden = false
                } else {
                    cell.buttonStackView.isHidden = true
                }

                // configure status (if exist)
                if let status = notification.status {
                    let frame = CGRect(
                        x: 0,
                        y: 0,
                        width: tableView.readableContentGuide.layoutFrame.width - NotificationStatusTableViewCell.statusPadding.left - NotificationStatusTableViewCell.statusPadding.right,
                        height: tableView.readableContentGuide.layoutFrame.height
                    )
                    StatusSection.configure(
                        cell: cell,
                        tableView: tableView,
                        timelineContext: .notifications,
                        dependency: dependency,
                        readableLayoutFrame: frame,
                        status: status,
                        requestUserID: notification.userID,
                        statusItemAttribute: attribute
                    )
                    cell.statusContainerView.isHidden = false
                    cell.containerStackView.alignment = .top
                    cell.containerStackViewBottomLayoutConstraint.constant = 0
                } else {
                    if case .followRequest = notification.notificationType {
                        cell.containerStackView.alignment = .top
                    } else {
                        cell.containerStackView.alignment = .center
                    }
                    cell.statusContainerView.isHidden = true
                    cell.containerStackViewBottomLayoutConstraint.constant = 5  // 5pt margin when no status view
                }

                return cell

            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self)) as! TimelineBottomLoaderTableViewCell
                cell.startAnimating()
                return cell
            }
        }
    }
}

