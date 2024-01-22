//
//  FollowedTagsViewModel.swift
//  Mastodon
//
//  Created by Marcus Kida on 23.11.22.
//

import UIKit
import MastodonSDK
import MastodonCore

final class FollowedTagsViewModel: NSObject {
    private(set) var followedTags: [Mastodon.Entity.Tag]

    private weak var tableView: UITableView?
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?

    // input
    let context: AppContext
    let authContext: AuthContext

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.followedTags = []

        super.init()
    }
}

extension FollowedTagsViewModel {
    func setupTableView(_ tableView: UITableView) {
        setupDiffableDataSource(tableView: tableView)
        
        fetchFollowedTags()
    }
    
    func fetchFollowedTags(completion: (() -> Void)? = nil ) {
        Task { @MainActor in
            do {
                followedTags = try await context.apiService.getFollowedTags(
                    domain: authContext.mastodonAuthenticationBox.domain,
                    query: Mastodon.API.Account.FollowedTagsQuery(limit: nil),
                    authenticationBox: authContext.mastodonAuthenticationBox
                ).value

                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                let items = followedTags.compactMap { Item.hashtag($0) }
                snapshot.appendItems(items, toSection: .main)

                await diffableDataSource?.apply(snapshot)
            } catch {}

            completion?()
        }
    }

    func followOrUnfollow(_ tag: Mastodon.Entity.Tag) {
        Task { @MainActor in
            if tag.following ?? false {
                _ = try? await context.apiService.unfollowTag(
                    for: tag.name,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            } else {
                _ = try? await context.apiService.followTag(
                    for: tag.name,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            }
            
            fetchFollowedTags()
        }
    }
}

