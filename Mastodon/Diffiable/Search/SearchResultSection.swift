//
//  SearchResultSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import Foundation
import MastodonSDK
import UIKit
import CoreData
import CoreDataStack

enum SearchResultSection: Equatable, Hashable {
    case main
}

extension SearchResultSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) -> UITableViewDiffableDataSource<SearchResultSection, SearchResultItem> {
        UITableViewDiffableDataSource(tableView: tableView) { [
                weak statusTableViewCellDelegate
            ] tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .account(let account):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchResultTableViewCell.self), for: indexPath) as! SearchResultTableViewCell
                cell.config(with: account)
                return cell
            case .hashtag(let tag):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchResultTableViewCell.self), for: indexPath) as! SearchResultTableViewCell
                cell.config(with: tag)
                return cell
            case .status(let statusObjectID, let attribute):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: StatusTableViewCell.self), for: indexPath) as! StatusTableViewCell
                if let status = try? dependency.context.managedObjectContext.existingObject(with: statusObjectID) as? Status {
                    let activeMastodonAuthenticationBox = dependency.context.authenticationService.activeMastodonAuthenticationBox.value
                    let requestUserID = activeMastodonAuthenticationBox?.userID ?? ""
                    StatusSection.configure(
                        cell: cell,
                        tableView: tableView,
                        timelineContext: .search,
                        dependency: dependency,
                        readableLayoutFrame: tableView.readableContentGuide.layoutFrame,
                        status: status,
                        requestUserID: requestUserID,
                        statusItemAttribute: attribute
                    )
                }
                cell.delegate = statusTableViewCellDelegate
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
            }   // end switch
        }   // end UITableViewDiffableDataSource
    }   // end func
}
