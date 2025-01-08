//
//  DiscoverySection.swift
//  Mastodon
//
//  Created by MainasuK on 2022-4-13.
//

import UIKit
import MastodonCore
import MastodonUI
import MastodonSDK

enum DiscoverySection: CaseIterable {
    // case posts
    case hashtags
    case news
    case forYou
}

extension DiscoverySection {

    class Configuration {
        let authenticationBox: MastodonAuthenticationBox
        weak var profileCardTableViewCellDelegate: ProfileCardTableViewCellDelegate?
        let familiarFollowers: Published<[Mastodon.Entity.FamiliarFollowers]>.Publisher?

        public init(
            authenticationBox: MastodonAuthenticationBox,
            profileCardTableViewCellDelegate: ProfileCardTableViewCellDelegate? = nil,
            familiarFollowers: Published<[Mastodon.Entity.FamiliarFollowers]>.Publisher? = nil
        ) {
            self.authenticationBox = authenticationBox
            self.profileCardTableViewCellDelegate = profileCardTableViewCellDelegate
            self.familiarFollowers = familiarFollowers
        }
    }

    static func diffableDataSource(
        tableView: UITableView,
        configuration: Configuration
    ) -> UITableViewDiffableDataSource<DiscoverySection, DiscoveryItem> {
        
        tableView.register(TrendTableViewCell.self, forCellReuseIdentifier: String(describing: TrendTableViewCell.self))
        tableView.register(NewsTableViewCell.self, forCellReuseIdentifier: String(describing: NewsTableViewCell.self))
        tableView.register(ProfileCardTableViewCell.self, forCellReuseIdentifier: String(describing: ProfileCardTableViewCell.self))
        tableView.register(TimelineBottomLoaderTableViewCell.self, forCellReuseIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self))

        return UITableViewDiffableDataSource(tableView: tableView) {
            tableView,
            indexPath,
            item in
            switch item {
                case .hashtag(let tag):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TrendTableViewCell.self), for: indexPath) as? TrendTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                    cell.trendView.configure(tag: tag)
                    return cell
                case .link(let link):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: NewsTableViewCell.self), for: indexPath) as? NewsTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                    cell.newsView.configure(link: link)
                    return cell
                case .account(let account, relationship: let relationship):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ProfileCardTableViewCell.self), for: indexPath) as?
                        ProfileCardTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }

                    cell.configure(
                        tableView: tableView,
                        account: account,
                        relationship: relationship,
                        profileCardTableViewCellDelegate: configuration.profileCardTableViewCellDelegate
                    )

                    // bind familiarFollowers
                    if let familiarFollowers = configuration.familiarFollowers {
                        familiarFollowers
                            .map { array in array.first(where: { $0.id == account.id }) }
                            .assign(to: \.familiarFollowers, on: cell.profileCardView.viewModel)
                            .store(in: &cell.disposeBag)
                    } else {
                        cell.profileCardView.viewModel.familiarFollowers = nil
                    }

                    return cell
                case .bottomLoader:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: TimelineBottomLoaderTableViewCell.self), for: indexPath) as? TimelineBottomLoaderTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }
                    cell.activityIndicatorView.startAnimating()
                    return cell
            }
        }
    }

}
