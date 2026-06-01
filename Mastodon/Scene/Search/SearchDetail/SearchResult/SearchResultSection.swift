//
//  SearchResultSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import Foundation
import MastodonSDK
import UIKit
import MastodonAsset
import MastodonCore
import MastodonLocalization
import MastodonUI
import Combine

enum SearchResultSection: Hashable {
    case main
}

extension SearchResultSection {
    
    struct Configuration {
        let authenticationBox: MastodonAuthenticationBox
        weak var statusViewTableViewCellDelegate: StatusTableViewCellDelegate?
        weak var userTableViewCellDelegate: UserTableViewCellDelegate?
    }
    
    static func tableViewDiffableDataSource(
        tableView: UITableView,
        authenticationBox: MastodonAuthenticationBox,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<SearchResultSection, SearchResultItem> {
        tableView.register(UserTableViewCell.self, forCellReuseIdentifier: String(describing: UserTableViewCell.self))
        tableView.register(StatusTableViewCell.self, forCellReuseIdentifier: String(describing: StatusTableViewCell.self))
        tableView.register(HashtagTableViewCell.self, forCellReuseIdentifier: String(describing: HashtagTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
                case .account(let account, let relationship):
                    let cell = tableView.dequeueReusableCell(withIdentifier: UserTableViewCell.reuseIdentifier, for: indexPath) as! UserTableViewCell

                    guard let me = authenticationBox.cachedAccount else { return cell }

                    cell.userView.setButtonState(.loading)
                    cell.configure(
                        me: me,
                        tableView: tableView,
                        account: account,
                        relationship: relationship,
                        delegate: configuration.userTableViewCellDelegate
                    )
                return cell
            case .status(let status):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                let displayItem = StatusTableViewCell.StatusTableViewCellViewModel.DisplayItem.status(status)
                let contentConcealModel = StatusView.ContentConcealViewModel(status: status, filterBox: StatusFilterService.shared.activeFilterBox, filterContext: nil) // no filters in search results
                configure(
                    tableView: tableView,
                    cell: cell,
                    viewModel: StatusTableViewCell.StatusTableViewCellViewModel(displayItem: displayItem, contentConcealModel: contentConcealModel),
                    configuration: configuration
                )
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
        tableView: UITableView,
        cell: StatusTableViewCell,
        viewModel: StatusTableViewCell.StatusTableViewCellViewModel,
        configuration: Configuration
    ) {
        StatusSection.setupStatusPollDataSource(
            authenticationBox: configuration.authenticationBox,
            statusView: cell.statusView
        )
        
        cell.statusView.viewModel.authenticationBox = configuration.authenticationBox
        
        cell.configure(
            tableView: tableView,
            viewModel: viewModel,
            delegate: configuration.statusViewTableViewCellDelegate
        )
    }
}
