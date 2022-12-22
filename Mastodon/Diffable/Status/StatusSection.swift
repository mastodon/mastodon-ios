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
import AVKit
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

    static let logger = Logger(subsystem: "StatusSection", category: "logic")
    
    struct Configuration {
        let context: AppContext
        let authContext: AuthContext
        weak var statusTableViewCellDelegate: StatusTableViewCellDelegate?
        weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
        let filterContext: Mastodon.Entity.Filter.Context?
        let activeFilters: Published<[Mastodon.Entity.Filter]>.Publisher?
    }

    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<StatusSection, StatusItem> {
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(TimelineMiddleLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self))
        tableView.register(StatusThreadRootTableViewCell.self, forCellReuseIdentifier: String(describing: StatusThreadRootTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .feed(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        context: context,
                        tableView: tableView,
                        cell: cell,
                        viewModel: StatusTableViewCell.ViewModel(value: .feed(feed)),
                        configuration: configuration
                    )
                }
                return cell
            case .feedLoader(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineMiddleLoaderTableViewCell.self), for: indexPath) as! TimelineMiddleLoaderTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let feed = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        cell: cell,
                        feed: feed,
                        configuration: configuration
                    )
                }
                return cell
            case .status(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let status = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        context: context,
                        tableView: tableView,
                        cell: cell,
                        viewModel: StatusTableViewCell.ViewModel(value: .status(status)),
                        configuration: configuration
                    )
                }
                return cell
            case .thread(let thread):
                let cell = dequeueConfiguredReusableCell(
                    context: context,
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
        let thread: StatusItem.Thread
        let configuration: Configuration
    }

    static func dequeueConfiguredReusableCell(
        context: AppContext,
        tableView: UITableView,
        indexPath: IndexPath,
        configuration: ThreadCellRegistrationConfiguration
    ) -> UITableViewCell {
        let managedObjectContext = context.managedObjectContext
        
        switch configuration.thread {
        case .root(let threadContext):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusThreadRootTableViewCell.self), for: indexPath) as! StatusThreadRootTableViewCell
            managedObjectContext.performAndWait {
                guard let status = threadContext.status.object(in: managedObjectContext) else { return }
                StatusSection.configure(
                    context: context,
                    tableView: tableView,
                    cell: cell,
                    viewModel: StatusThreadRootTableViewCell.ViewModel(value: .status(status)),
                    configuration: configuration.configuration
                )
            }
            return cell
        case .reply(let threadContext),
             .leaf(let threadContext):
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
            managedObjectContext.performAndWait {
                guard let status = threadContext.status.object(in: managedObjectContext) else { return }
                StatusSection.configure(
                    context: context,
                    tableView: tableView,
                    cell: cell,
                    viewModel: StatusTableViewCell.ViewModel(value: .status(status)),
                    configuration: configuration.configuration
                )
            }
            return cell
        }
    }
    
}

extension StatusSection {
    
    public static func setupStatusPollDataSource(
        context: AppContext,
        authContext: AuthContext,
        statusView: StatusView
    ) {
        let managedObjectContext = context.managedObjectContext
        statusView.pollTableViewDiffableDataSource = UITableViewDiffableDataSource<PollSection, PollItem>(tableView: statusView.pollTableView) { tableView, indexPath, item in
            switch item {
            case .option(let record):
                // Fix cell reuse animation issue
                let cell: PollOptionTableViewCell = {
                    let _cell = tableView.dequeueReusableCell(withIdentifier: String(describing: PollOptionTableViewCell.self) + "@\(indexPath.row)#\(indexPath.section)") as? PollOptionTableViewCell
                    _cell?.prepareForReuse()
                    return _cell ?? PollOptionTableViewCell()
                }()
                
                cell.pollOptionView.viewModel.authContext = authContext
                
                managedObjectContext.performAndWait {
                    guard let option = record.object(in: managedObjectContext) else {
                        assertionFailure()
                        return
                    }
                    
                    cell.pollOptionView.configure(pollOption: option)
                    
                    // trigger update if needs
                    let needsUpdatePoll: Bool = {
                        // check first option in poll to trigger update poll only once
                        guard option.index == 0 else { return false }

                        let poll = option.poll
                        guard !poll.expired else {
                            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): poll expired. Skip update poll \(poll.id)")
                            return false
                        }

                        let now = Date()
                        let timeIntervalSinceUpdate = now.timeIntervalSince(poll.updatedAt)
                        #if DEBUG
                        let autoRefreshTimeInterval: TimeInterval = 3 // speedup testing
                        #else
                        let autoRefreshTimeInterval: TimeInterval = 30
                        #endif

                        guard timeIntervalSinceUpdate > autoRefreshTimeInterval else {
                            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): skip update poll \(poll.id) due to recent updated")
                            return false
                        }
                        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): update poll \(poll.id)…")
                        return true
                    }()

                    if needsUpdatePoll {
                        let pollRecord: ManagedObjectRecord<Poll> = .init(objectID: option.poll.objectID)
                        Task { [weak context] in
                            guard let context = context else { return }
                            _ = try await context.apiService.poll(
                                poll: pollRecord,
                                authenticationBox: authContext.mastodonAuthenticationBox
                            )
                        }
                    }
                }   // end managedObjectContext.performAndWait
                return cell
            }
        }
        var _snapshot = NSDiffableDataSourceSnapshot<PollSection, PollItem>()
        _snapshot.appendSections([.main])
        if #available(iOS 15.0, *) {
            statusView.pollTableViewDiffableDataSource?.applySnapshotUsingReloadData(_snapshot)
        } else {
            statusView.pollTableViewDiffableDataSource?.apply(_snapshot, animatingDifferences: false)
        }
    }
}

extension StatusSection {
    
    static func configure(
        context: AppContext,
        tableView: UITableView,
        cell: StatusTableViewCell,
        viewModel: StatusTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        setupStatusPollDataSource(
            context: context,
            authContext: configuration.authContext,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.context = configuration.context
        cell.statusView.viewModel.authContext = configuration.authContext
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
        
        cell.statusView.viewModel.filterContext = configuration.filterContext
        configuration.activeFilters?
            .assign(to: \.activeFilters, on: cell.statusView.viewModel)
            .store(in: &cell.disposeBag)
    }
    
    static func configure(
        context: AppContext,
        tableView: UITableView,
        cell: StatusThreadRootTableViewCell,
        viewModel: StatusThreadRootTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        setupStatusPollDataSource(
            context: context,
            authContext: configuration.authContext,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.context = configuration.context
        cell.statusView.viewModel.authContext = configuration.authContext
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
        
        cell.statusView.viewModel.filterContext = configuration.filterContext
        configuration.activeFilters?
            .assign(to: \.activeFilters, on: cell.statusView.viewModel)
            .store(in: &cell.disposeBag)
    }
    
    static func configure(
        cell: TimelineMiddleLoaderTableViewCell,
        feed: Feed,
        configuration: Configuration
    ) {
        cell.configure(
            feed: feed,
            delegate: configuration.timelineMiddleLoaderTableViewCellDelegate
        )
    }
    
}
