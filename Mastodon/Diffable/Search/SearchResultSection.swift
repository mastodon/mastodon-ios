//
//  SearchResultSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import os.log
import Foundation
import MastodonSDK
import UIKit
import CoreData
import CoreDataStack
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI

enum SearchResultSection: Hashable {
    case main
}

extension SearchResultSection {
    
    static let logger = Logger(subsystem: "SearchResultSection", category: "logic")
    
    struct Configuration {
        let authContext: AuthContext
        weak var statusViewTableViewCellDelegate: StatusTableViewCellDelegate?
        weak var userTableViewCellDelegate: UserTableViewCellDelegate?
    }
    
    static func tableViewDiffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<SearchResultSection, SearchResultItem> {
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(HashtagTableViewCell.self, forCellReuseIdentifier: String(describing: HashtagTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .user(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UserTableViewCell.self), for: indexPath) as! UserTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let user = record.object(in: context.managedObjectContext) else { return }
                    configure(
                        context: context,
                        tableView: tableView,
                        cell: cell,
                        viewModel: .init(value: .user(user)),
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
            case .hashtag(let tag):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: HashtagTableViewCell.self)) as! HashtagTableViewCell
                cell.primaryLabel.configure(content: PlaintextMetaContent(string: "#" + tag.name))
                return cell
            case .bottomLoader(let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self)) as! TimelineBottomLoaderTableViewCell
                if attribute.isNoResult {
                    cell.stopAnimating()
                    cell.loadMoreLabel.text = L10n.Scene.Search.Searching.EmptyState.noResults
                    cell.loadMoreLabel.textColor = Asset.Colors.Label.secondary.color
                    cell.loadMoreLabel.isHidden = false
                } else {
                    cell.startAnimating()
                    cell.loadMoreLabel.isHidden = true
                }
                return cell
            }
        }   // end UITableViewDiffableDataSource
    }   // end func
}

extension SearchResultSection {
    
    static func configure(
        context: AppContext,
        tableView: UITableView,
        cell: StatusTableViewCell,
        viewModel: StatusTableViewCell.ViewModel,
        configuration: Configuration
    ) {
        StatusSection.setupStatusPollDataSource(
            context: context,
            authContext: configuration.authContext,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.context = context
        cell.statusView.viewModel.authContext = configuration.authContext
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusViewTableViewCellDelegate
        )
    }
    
    static func configure(
        context: AppContext,
        tableView: UITableView,
        cell: UserTableViewCell,
        viewModel: UserTableViewCell.ViewModel,
        configuration: Configuration
    ) {        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.userTableViewCellDelegate
        )
    }
    
}
