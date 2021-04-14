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
    case account
    case hashtag
    case mixed
    case bottomLoader
}

extension SearchResultSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency
    ) -> UITableViewDiffableDataSource<SearchResultSection, SearchResultItem> {
        UITableViewDiffableDataSource(tableView: tableView) { (tableView, indexPath, result) -> UITableViewCell? in
            switch result {
            case .account(let account):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchingTableViewCell.self), for: indexPath) as! SearchingTableViewCell
                cell.config(with: account)
                return cell
            case .hashtag(let tag):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchingTableViewCell.self), for: indexPath) as! SearchingTableViewCell
                cell.config(with: tag)
                return cell
            case .hashtagObjectID(let hashtagObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchingTableViewCell.self), for: indexPath) as! SearchingTableViewCell
                let tag  = dependency.context.managedObjectContext.object(with: hashtagObjectID) as! Tag
                cell.config(with: tag)
                return cell
            case .accountObjectID(let accountObjectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SearchingTableViewCell.self), for: indexPath) as! SearchingTableViewCell
                let user  = dependency.context.managedObjectContext.object(with: accountObjectID) as! MastodonUser
                cell.config(with: user)
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: CommonBottomLoader.self)) as! CommonBottomLoader
                cell.startAnimating()
                return cell
            }
        }
    }
}
