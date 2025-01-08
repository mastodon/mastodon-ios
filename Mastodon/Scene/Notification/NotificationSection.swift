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
import MetaTextKit
import MastodonMeta
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

enum NotificationSection: Equatable, Hashable {
    case main
}

extension NotificationSection {
    
    struct Configuration {
        let authenticationBox: MastodonAuthenticationBox
        weak var notificationTableViewCellDelegate: NotificationTableViewCellDelegate?
        let filterContext: Mastodon.Entity.FilterContext?
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<NotificationSection, NotificationItem> {
        tableView.register(NotificationTableViewCell.self, forCellReuseIdentifier: String(describing: NotificationTableViewCell.self))
        tableView.register(AccountWarningNotificationCell.self, forCellReuseIdentifier: AccountWarningNotificationCell.reuseIdentifier)
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        tableView.register(NotificationFilteringBannerTableViewCell.self, forCellReuseIdentifier: NotificationFilteringBannerTableViewCell.reuseIdentifier)

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .feed(let feed):
                if let notification = feed.notification, let accountWarning = notification.accountWarning {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: AccountWarningNotificationCell.reuseIdentifier, for: indexPath) as? AccountWarningNotificationCell else {
                        assertionFailure("unexpected cell dequeued")
                        return nil
                    }
                    cell.configure(with: accountWarning)
                    return cell
                } else {
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as? NotificationTableViewCell else {
                        assertionFailure("unexpected cell dequeued")
                        return nil
                    }
                    configure(
                        tableView: tableView,
                        cell: cell,
                        viewModel: NotificationTableViewCell.ViewModel(value: .feed(feed)),
                        configuration: configuration
                    )
                    return cell
                }

            case .feedLoader:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as? TimelineBottomLoaderTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                cell.activityIndicatorView.startAnimating()
                return cell
            case .bottomLoader:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as? TimelineBottomLoaderTableViewCell else { assertionFailure("unexpected cell dequeued")
                    return nil
                }
                cell.activityIndicatorView.startAnimating()
                return cell

            case .filteredNotifications(let policy):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationFilteringBannerTableViewCell.reuseIdentifier, for: indexPath) as? NotificationFilteringBannerTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                cell.configure(with: policy)

                return cell
            }
        }
    }
}

extension NotificationSection {
    
    static func configure(
        tableView: UITableView,
        cell: NotificationTableViewCell,
        viewModel: NotificationTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        StatusSection.setupStatusPollDataSource(
            authenticationBox: configuration.authenticationBox,
            statusView: cell.notificationView.statusView
        )
        
        StatusSection.setupStatusPollDataSource(
            authenticationBox: configuration.authenticationBox,
            statusView: cell.notificationView.quoteStatusView
        )
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.notificationTableViewCellDelegate,
            authenticationBox: configuration.authenticationBox
        )
    }
    
}

