//
//  TimelineSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/1/27.
//

import Combine
import CoreData // needed until ReportStatusViewController is replaced
import CoreDataStack // needed until ReportStatusViewController is replaced
import UIKit
import AlamofireImage
import MastodonMeta
import MastodonSDK
import NaturalLanguage
import MastodonCore
import MastodonUI

enum StatusSection: Equatable, Hashable {
    case main
}

extension StatusSection {

    struct Configuration {
        let authenticationBox: MastodonAuthenticationBox
        weak var statusTableViewCellDelegate: StatusTableViewCellDelegate?
        weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
        let filterContext: Mastodon.Entity.FilterContext?
    }

    static func diffableDataSource(
        tableView: UITableView,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<StatusSection, MastodonItemIdentifier> {
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(StatusThreadRootTableViewCell.self, forCellReuseIdentifier: String(describing: StatusThreadRootTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .feed(let feed):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                let displayItem = StatusTableViewCell.StatusTableViewCellViewModel.DisplayItem.feed(feed)
                let contentConcealModel = StatusView.ContentConcealViewModel(status: feed.status, filterBox: StatusFilterService.shared.activeFilterBox, filterContext: configuration.filterContext)
                configure(
                    tableView: tableView,
                    cell: cell,
                    viewModel: StatusTableViewCell.StatusTableViewCellViewModel(displayItem: displayItem, contentConcealModel: contentConcealModel),
                    configuration: configuration
                )
                return cell
            case .feedLoader(let feed):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                configure(
                    cell: cell,
                    feed: feed,
                    configuration: configuration
                )
                return cell
            case .status(let status):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                let displayItem = StatusTableViewCell.StatusTableViewCellViewModel.DisplayItem.status(status)
                let contentConcealModel = StatusView.ContentConcealViewModel(status: status, filterBox: StatusFilterService.shared.activeFilterBox, filterContext: configuration.filterContext)
                configure(
                    tableView: tableView,
                    cell: cell,
                    viewModel: StatusTableViewCell.StatusTableViewCellViewModel(displayItem: displayItem, contentConcealModel: contentConcealModel),
                    configuration: configuration
                )
                return cell
            case .thread(let thread):
                let cell = dequeueConfiguredReusableCell(
                    tableView: tableView,
                    indexPath: indexPath,
                    configuration: ThreadCellRegistrationConfiguration(
                        thread: thread,
                        configuration: configuration
                    )
                )
                return cell
            case .topLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }   // end func
    
}

extension StatusSection {
    
    struct ThreadCellRegistrationConfiguration {
        let thread: MastodonItemIdentifier.Thread
        let configuration: Configuration
    }

    static func dequeueConfiguredReusableCell(
        tableView: UITableView,
        indexPath: IndexPath,
        configuration: ThreadCellRegistrationConfiguration
    ) -> UITableViewCell {        
        switch configuration.thread {
        case .root(let threadContext):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusThreadRootTableViewCell.self), for: indexPath) as! StatusThreadRootTableViewCell
            let contentConcealModel = StatusView.ContentConcealViewModel(status: threadContext.status, filterBox: StatusFilterService.shared.activeFilterBox, filterContext: .thread)
            StatusSection.configure(
                tableView: tableView,
                cell: cell,
                viewModel: StatusTableViewCell.StatusTableViewCellViewModel(displayItem: .status(threadContext.status), contentConcealModel: contentConcealModel),
                configuration: configuration.configuration
            )
            return cell
        case .reply(let threadContext),
             .leaf(let threadContext):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
            let displayItem = StatusTableViewCell.StatusTableViewCellViewModel.DisplayItem.status(threadContext.status)
            let contentConcealModel = StatusView.ContentConcealViewModel(status: threadContext.status, filterBox: StatusFilterService.shared.activeFilterBox, filterContext: configuration.configuration.filterContext)
            assert(configuration.configuration.filterContext == .thread)
            StatusSection.configure(
                tableView: tableView, cell: cell,
                viewModel: StatusTableViewCell.StatusTableViewCellViewModel(displayItem: displayItem, contentConcealModel: contentConcealModel),
                configuration: configuration.configuration
            )
            return cell
        }
    }
    
}

extension StatusSection {
    
    public static func setupStatusPollDataSource(
        authenticationBox: MastodonAuthenticationBox,
        statusView: StatusView
    ) {
        statusView.pollTableViewDiffableDataSource = UITableViewDiffableDataSource<PollSection, PollItem>(tableView: statusView.pollTableView) { tableView, indexPath, item in
            switch item {
            case .history:
                return nil
            case .pollOption(let option):
                // Fix cell reuse animation issue
                let cell: PollOptionTableViewCell = {
                    let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PollOptionTableViewCell.self) + "@\(indexPath.row)#\(indexPath.section)") as? PollOptionTableViewCell
                    _cell?.prepareForReuse()
                    return _cell ?? PollOptionTableViewCell()
                }()
                return cell
            case .option(let record):
                // Fix cell reuse animation issue
                let cell: PollOptionTableViewCell = {
                    let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PollOptionTableViewCell.self) + "@\(indexPath.row)#\(indexPath.section)") as? PollOptionTableViewCell
                    _cell?.prepareForReuse()
                    return _cell ?? PollOptionTableViewCell()
                }()
                
                cell.pollOptionView.viewModel.authenticationBox = authenticationBox

                cell.pollOptionView.configure(pollOption: record)

                return cell
            }
        }
        var _snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
        _snapshot.appendSections([.main])
        statusView.pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(_snapshot)
    }
}

extension StatusSection {
    
    public static func setupStatusPollHistoryDataSource(
        context: AppContext,
        authenticationBox: MastodonAuthenticationBox,
        statusView: StatusView
    ) {
        statusView.pollTableViewDiffableDataSource = UITableViewDiffableDataSource<PollSection, PollItem>(tableView: statusView.pollTableView) { tableView, indexPath, item in
            switch item {
            case .pollOption:
                return nil
            case .option:
                return nil
            case let .history(option):
                // Fix cell reuse animation issue
                let cell: PollOptionTableViewCell = {
                    let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PollOptionTableViewCell.self) + "@\(indexPath.row)#\(indexPath.section)") as? PollOptionTableViewCell
                    _cell?.prepareForReuse()
                    return _cell ?? PollOptionTableViewCell()
                }()
                
                cell.pollOptionView.configure(historyPollOption: option)

                return cell
            }
        }
    }
}

extension StatusSection {
    
    static func configure(
        tableView: UITableView,
        cell: StatusTableViewCell,
        viewModel: StatusTableViewCell.StatusTableViewCellViewModel,
        configuration: Configuration
    ) {
        setupStatusPollDataSource(
            authenticationBox: configuration.authenticationBox,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.authenticationBox = configuration.authenticationBox
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
    }
    
    static func configure(
        tableView: UITableView,
        cell: StatusThreadRootTableViewCell,
        viewModel: StatusTableViewCell.StatusTableViewCellViewModel,
        configuration: Configuration
    ) {
        setupStatusPollDataSource(
            authenticationBox: configuration.authenticationBox,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.authenticationBox = configuration.authenticationBox
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
    }
    
    static func configure(
        cell: TimelineMiddleLoaderTableViewCell,
        feed: MastodonFeed,
        configuration: Configuration
    ) {
        cell.configure(
            feed: feed,
            delegate: configuration.timelineMiddleLoaderTableViewCellDelegate
        )
    }
    
}
