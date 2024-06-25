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
        let authContext: AuthContext
        weak var notificationTableViewCellDelegate: NotificationTableViewCellDelegate?
        let filterContext: Mastodon.Entity.Filter.Context?
        let activeFilters: Published<[Mastodon.Entity.Filter]>.Publisher?
    }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
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
                    let cell = tableView.dequeueReusableCell(withIdentifier: AccountWarningNotificationCell.reuseIdentifier, for: indexPath) as! AccountWarningNotificationCell
                    cell.configure(with: accountWarning)
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as! NotificationTableViewCell
                    configure(
                        context: context,
                        tableView: tableView,
                        cell: cell,
                        viewModel: NotificationTableViewCell.ViewModel(value: .feed(feed)),
                        configuration: configuration
                    )
                    return cell
                }

            case .feedLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell

            case .filteredNotifications(let policy):
                let cell = tableView.dequeueReusableCell(withIdentifier: NotificationFilteringBannerTableViewCell.reuseIdentifier, for: indexPath) as! NotificationFilteringBannerTableViewCell
                cell.configure(with: policy)

                return cell
            }
        }
    }
}

extension NotificationSection {
    
    static func configure(
        context: AppContext,
        tableView: UITableView,
        cell: NotificationTableViewCell,
        viewModel: NotificationTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        StatusSection.setupStatusPollDataSource(
            context: context,
            authContext: configuration.authContext,
            statusView: cell.notificationView.statusView
        )
        
        StatusSection.setupStatusPollDataSource(
            context: context,
            authContext: configuration.authContext,
            statusView: cell.notificationView.quoteStatusView
        )
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.notificationTableViewCellDelegate,
            authenticationBox: configuration.authContext.mastodonAuthenticationBox
        )
        
        cell.notificationView.statusView.viewModel.filterContext = configuration.filterContext
        cell.notificationView.quoteStatusView.viewModel.filterContext = configuration.filterContext
        
        configuration.activeFilters?
            .assign(to: \.activeFilters, on: cell.notificationView.statusView.viewModel)
            .store(in: &cell.disposeBag)
        configuration.activeFilters?
            .assign(to: \.activeFilters, on: cell.notificationView.quoteStatusView.viewModel)
            .store(in: &cell.disposeBag)
    }
    
}

