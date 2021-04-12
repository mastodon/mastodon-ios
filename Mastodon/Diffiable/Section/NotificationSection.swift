//
//  NotificationSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/13.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import Combine

enum NotificationSection: Equatable, Hashable {
    case main
}

extension NotificationSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        timestampUpdatePublisher: AnyPublisher<Date, Never>,
        managedObjectContext: NSManagedObjectContext
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {

        return UITableViewDiffableDataSource(tableView: tableView) { (tableView, indexPath, notificationItem) -> UITableViewCell? in
            switch notificationItem {
            case .notification(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as! NotificationTableViewCell
                let notification = managedObjectContext.object(with: objectID) as! MastodonNotification
                let type = Mastodon.Entity.Notification.NotificationType(rawValue: notification.type)
                
                var actionText: String
                var actionImageName: String
                switch type {
                case .follow:
                    actionText = L10n.Scene.Notification.Action.follow
                    actionImageName = "person.crop.circle.badge.checkmark"
                case .favourite:
                    actionText = L10n.Scene.Notification.Action.favourite
                    actionImageName = "star.fill"
                case .reblog:
                    actionText = L10n.Scene.Notification.Action.reblog
                    actionImageName = "arrow.2.squarepath"
                case .mention:
                    actionText = L10n.Scene.Notification.Action.mention
                    actionImageName = "at"
                case .poll:
                    actionText = L10n.Scene.Notification.Action.poll
                    actionImageName = "list.bullet"
                default:
                    actionText = ""
                    actionImageName = ""
                }
                
                timestampUpdatePublisher
                    .sink { _ in
                        let timeText = notification.createAt.shortTimeAgoSinceNow
                        cell.actionLabel.text = actionText + " · " + timeText
                    }
                    .store(in: &cell.disposeBag)
                cell.nameLabel.text = notification.account.displayName
                
                if let actionImage = UIImage(systemName: actionImageName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))?.withRenderingMode(.alwaysTemplate) {
                    cell.actionImageView.image = actionImage
                }
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchBottomLoader.self)) as! SearchBottomLoader
                cell.startAnimating()
                return cell
            }
        }
    }
}
