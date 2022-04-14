//
//  DiscoverySection.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import os.log
import UIKit
import MastodonUI

enum DiscoverySection: CaseIterable {
    // case posts
    case hashtags
    case news
    case forYou
}

extension DiscoverySection {
    
    static let logger = Logger(subsystem: "DiscoverySection", category: "logic")
    
    struct Configuration { }
    
    static func diffableDataSource(
        tableView: UITableView,
        context: AppContext,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem> {
        tableView.register(TrendTableViewCell.self, forCellReuseIdentifier: String(describing: TrendTableViewCell.self))
        tableView.register(NewsTableViewCell.self, forCellReuseIdentifier: String(describing: NewsTableViewCell.self))
        tableView.register(ProfileCardTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileCardTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .hashtag(let tag):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TrendTableViewCell.self), for: indexPath) as! TrendTableViewCell
                cell.trendView.configure(tag: tag)
                return cell
            case .link(let link):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NewsTableViewCell.self), for: indexPath) as! NewsTableViewCell
                cell.newsView.configure(link: link)
                return cell
            case .user(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileCardTableViewCell.self), for: indexPath) as! ProfileCardTableViewCell
                context.managedObjectContext.performAndWait {
                    guard let user = record.object(in: context.managedObjectContext) else { return }
                    cell.profileCardView.configure(user: user)
                }
                context.authenticationService.activeMastodonAuthentication
                    .map { $0?.user }
                    .assign(to: \.me, on: cell.profileCardView.viewModel.relationshipViewModel)
                    .store(in: &cell.disposeBag)
                return cell
            case .bottomLoader:
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as! TimelineBottomLoaderTableViewCell
                cell.activityIndicatorView.startAnimating()
                return cell
            }
        }
    }
    
}
