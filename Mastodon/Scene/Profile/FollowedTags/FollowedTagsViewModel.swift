//
//  FollowedTagsViewModel.swift
//  Mastodon
//
//  Created by Marcus Kida on 23.11.22.
//

import UIKit
import MastodonSDK
import MastodonCore
import Combine

final class FollowedTagsViewModel: NSObject {
    private var disposeBag = [AnyCancellable]()
    private(set) var followedTags: [Mastodon.Entity.Tag] = []

    private weak var tableView: UITableView?
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?

    // input
    let context: AppContext
    let authContext: AuthContext
    
    @Published var records = [Mastodon.Entity.Tag]()
    
    // output
    let presentHashtagTimeline = PassthroughSubject<HashtagTimelineViewModel, Never>()

    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext

        super.init()

            $records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(records.map {.hashtag($0) })
                self.diffableDataSource?.apply(snapshot, animatingDifferences: true)
            }
            .store(in: &disposeBag)
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
            switch tag.following {
            case .none:
                break
            case .some(true):
                _ = try? await context.apiService.unfollowTag(
                    for: tag.name,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            case .some(false):
                _ = try? await context.apiService.followTag(
                    for: tag.name,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            }
            
            fetchFollowedTags()
        }
    }
}

extension FollowedTagsViewModel: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let object = records[indexPath.row]

        let hashtagTimelineViewModel = HashtagTimelineViewModel(
            context: self.context,
            authContext: self.authContext,
            hashtag: object.name
        )
        
        presentHashtagTimeline.send(hashtagTimelineViewModel)
    }
}
