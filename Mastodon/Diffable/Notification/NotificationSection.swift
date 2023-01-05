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
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))
        
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .feed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NotificationTableViewCell.self), for: indexPath) as! NotificationTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        context: context,
                        tableView: tableView,
                        cell: cell,
                        viewModel: NotificationTableViewCell.ViewModel(value: .feed(feed)),
                        configuration: configuration
                    )
                }
                return cell
            case .feedLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
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
        cell.notificationView.viewModel.context = context
        cell.notificationView.viewModel.authContext = configuration.authContext
        
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
            delegate: configuration.notificationTableViewCellDelegate
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

