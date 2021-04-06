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
    case bottomLoader
}

extension SearchResultSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView
    ) -> UITableViewDiffableDataSource<SearchResultSection, SearchResultItem> {
        UITableViewDiffableDataSource(tableView: tableView) { (tableView, indexPath, result) -> UITableViewCell? in
            switch result {
            case .account(let account):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchingTableViewCell.self), for: indexPath) as! SearchingTableViewCell
                cell.config(with: account)
                return cell
            case .hashTag(let tag):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchingTableViewCell.self), for: indexPath) as! SearchingTableViewCell
                cell.config(with: tag)
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchBottomLoader.self)) as! SearchBottomLoader
                cell.startAnimating()
                return cell
            }
        }
    }
}
