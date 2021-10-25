//
//  SearchHistorySection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import UIKit
import CoreDataStack

enum SearchHistorySection: Hashable {
    case main
}

extension SearchHistorySection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency
    ) -> UITableViewDiffableDataSource<SearchHistorySection, SearchHistoryItem> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .account(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchResultTableViewCell.self), for: indexPath) as! SearchResultTableViewCell
                if let user = try? dependency.context.managedObjectContext.existingObject(with: objectID) as? MastodonUser {
                    cell.config(with: user)
                }
                return cell
            case .hashtag(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchResultTableViewCell.self), for: indexPath) as! SearchResultTableViewCell
                if let hashtag = try? dependency.context.managedObjectContext.existingObject(with: objectID) as? Tag {
                    cell.config(with: hashtag)
                }
                return cell
            case .status:
                // Should not show status in the history list
                return UITableViewCell()
            }   // end switch
        }   // end UITableViewDiffableDataSource
    }   // end func
}
