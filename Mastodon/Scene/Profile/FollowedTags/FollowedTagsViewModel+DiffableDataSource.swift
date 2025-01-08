//
//  FollowedTagsViewModel+DiffableDataSource.swift
//  Mastodon
//
//  Created by Marcus Kida on 01.12.22.
//

import UIKit
import MastodonSDK
import MastodonCore

extension FollowedTagsViewModel {
    enum Section: Hashable {
        case main
    }
    
    enum Item: Hashable {
        case hashtag(Mastodon.Entity.Tag)
    }
    
    func tableViewDiffableDataSource(
        for tableView: UITableView
    ) -> UITableViewDiffableDataSource<Section, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case let .hashtag(tag):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: FollowedTagsTableViewCell.reuseIdentifier, for: indexPath) as? FollowedTagsTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }

                cell.setup(self)
                cell.populate(with: tag)
                return cell
            }
        }
    }
    
    func setupDiffableDataSource(tableView: UITableView) {
        diffableDataSource = tableViewDiffableDataSource(for: tableView)

        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
    }
}
