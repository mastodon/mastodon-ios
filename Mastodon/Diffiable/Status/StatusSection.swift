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
import MastodonUI

enum StatusSection: Equatable, Hashable {
    case main
}

extension StatusSection {

    static let logger = Logger(subsystem: "StatusSection", category: "logic")
    
    struct Configuration {
        weak var statusTableViewCellDelegate: StatusTableViewCellDelegate?
        weak var timelineMiddleLoaderTableViewCellDelegate: TimelineMiddleLoaderTableViewCellDelegate?
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
                
                context.authenticationService.activeMastodonAuthenticationBox
                    .map { $0 as UserIdentifier? }
                    .assign(to: \.userIdentifier, on: cell.pollOptionView.viewModel)
                    .store(in: &cell.disposeBag)
                
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

                    if needsUpdatePoll, let authenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value
                    {
                        let pollRecord: ManagedObjectRecord<Poll> = .init(objectID: option.poll.objectID)
                        Task { [weak context] in
                            guard let context = context else { return }
                            _ = try await context.apiService.poll(
                                poll: pollRecord,
                                authenticationBox: authenticationBox
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
            statusView: cell.statusView
        )
        
        context.authenticationService.activeMastodonAuthenticationBox
            .map { $0 as UserIdentifier? }
            .assign(to: \.userIdentifier, on: cell.statusView.viewModel)
            .store(in: &cell.disposeBag)
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
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
            statusView: cell.statusView
        )
        
        context.authenticationService.activeMastodonAuthenticationBox
            .map { $0 as UserIdentifier? }
            .assign(to: \.userIdentifier, on: cell.statusView.viewModel)
            .store(in: &cell.disposeBag)
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusTableViewCellDelegate
        )
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

extension StatusSection {

    enum TimelineContext {
        case home
        case notifications
        case `public`
        case thread
        case account

        case favorite
        case hashtag
        case report
        case search

        var filterContext: Mastodon.Entity.Filter.Context? {
            switch self {
            case .home:             return .home
            case .notifications:    return .notifications
            case .public:           return .public
            case .thread:           return .thread
            case .account:          return .account
            default:                return nil
            }
        }
    }

    private static func needsFilterStatus(
        content: MastodonMetaContent?,
        filters: [Mastodon.Entity.Filter],
        timelineContext: TimelineContext
    ) -> AnyPublisher<Bool, Never> {
        guard let content = content,
              let currentFilterContext = timelineContext.filterContext,
              !filters.isEmpty else {
            return Just(false).eraseToAnyPublisher()
        }

        return Future<Bool, Never> { promise in
            DispatchQueue.global(qos: .userInteractive).async {
                var wordFilters: [Mastodon.Entity.Filter] = []
                var nonWordFilters: [Mastodon.Entity.Filter] = []
                for filter in filters {
                    guard filter.context.contains(where: { $0 == currentFilterContext }) else { continue }
                    if filter.wholeWord {
                        wordFilters.append(filter)
                    } else {
                        nonWordFilters.append(filter)
                    }
                }

                let text = content.original.lowercased()

                var needsFilter = false
                for filter in nonWordFilters {
                    guard text.contains(filter.phrase.lowercased()) else { continue }
                    needsFilter = true
                    break
                }

                if needsFilter {
                    DispatchQueue.main.async {
                        promise(.success(true))
                    }
                    return
                }

                let tokenizer = NLTokenizer(unit: .word)
                tokenizer.string = text
                let phraseWords = wordFilters.map { $0.phrase.lowercased() }
                tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
                    let word = String(text[range])
                    if phraseWords.contains(word) {
                        needsFilter = true
                        return false
                    } else {
                        return true
                    }
                }

                DispatchQueue.main.async {
                    promise(.success(needsFilter))
                }
            }
        }
        .eraseToAnyPublisher()
    }

}

class StatusContentOperation: Operation {

    let logger = Logger(subsystem: "StatusContentOperation", category: "logic")

    // input
    let statusObjectID: NSManagedObjectID
    let mastodonContent: MastodonContent

    // output
    var result: Result<MastodonMetaContent, Error>?

    init(
        statusObjectID: NSManagedObjectID,
        mastodonContent: MastodonContent
    ) {
        self.statusObjectID = statusObjectID
        self.mastodonContent = mastodonContent
        super.init()
    }

    override func main() {
        guard !isCancelled else { return }
        // logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): prcoess \(self.statusObjectID)…")

        do {
            let content = try MastodonMetaContent.convert(document: mastodonContent)
            result = .success(content)
            // logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): process success \(self.statusObjectID)")
        } catch {
            result = .failure(error)
            // logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): process fail \(self.statusObjectID)")
        }

    }

    override func cancel() {
        // logger.debug("\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): cancel \(self.statusObjectID.debugDescription)")
        super.cancel()
    }
}
