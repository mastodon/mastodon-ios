//
//  SearchResultSection.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import Foundation
import MastodonSDK
import UIKit

enum SearchResultSection: Equatable, Hashable {
    case account
    case hashTag
}

extension SearchResultSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView
    ) -> UITableViewDiffableDataSource<SearchResultSection, SearchResultItem> {
        UITableViewDiffableDataSource(tableView: tableView) { (tableView, indexPath, result) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchingTableViewCell.self), for: indexPath) as! SearchingTableViewCell
            switch result {
            case .account(let account):
                cell.config(with: account)
            case .hashTag(let tag):
                cell.config(with: tag)
            }
            return cell
        }
    }
}
