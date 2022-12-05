//
//  FollowedTagsViewModel.swift
//  Mastodon
//
//  Created by Marcus Kida on 23.11.22.
//

import os
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCore

final class FollowedTagsViewModel: NSObject {
    let logger = Logger(subsystem: String(describing: FollowedTagsViewModel.self), category: "ViewModel")
    var disposeBag = Set<AnyCancellable>()
    let fetchedResultsController: FollowedTagsFetchedResultController

    private weak var tableView: UITableView?
    var diffableDataSource: UITableViewDiffableDataSource<Section, Item>?

    // input
    let context: AppContext
    let authContext: AuthContext
    
    // output
    let presentHashtagTimeline = PassthroughSubject<HashtagTimelineViewModel, Never>()
    
    init(context: AppContext, authContext: AuthContext) {
        self.context = context
        self.authContext = authContext
        self.fetchedResultsController = FollowedTagsFetchedResultController(
            managedObjectContext: context.managedObjectContext,
            domain: authContext.mastodonAuthenticationBox.domain,
            user: authContext.mastodonAuthenticationBox.authenticationRecord.object(in: context.managedObjectContext)!.user
        )

        super.init()

        self.fetchedResultsController
            .$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
                snapshot.appendSections([.main])
                snapshot.appendItems(records.map {.hashtag($0) })
                self.diffableDataSource?.applySnapshot(snapshot, animated: true)
            }
            .store(in: &disposeBag)
    }
}

extension FollowedTagsViewModel {
    func setupTableView(_ tableView: UITableView) {
        self.tableView = tableView
        setupDiffableDataSource(tableView: tableView)
        tableView.delegate = self
        
        fetchFollowedTags()
    }
    
    func fetchFollowedTags() {
        Task { @MainActor in
            try await context.apiService.getFollowedTags(
                domain: authContext.mastodonAuthenticationBox.domain,
                query: Mastodon.API.Account.FollowedTagsQuery(limit: nil),
                authenticationBox: authContext.mastodonAuthenticationBox
            )
        }
    }

    func followOrUnfollow(_ tag: Tag) {
        Task { @MainActor in
            switch tag.following {
            case true:
                _ = try? await context.apiService.unfollowTag(
                    for: tag.name,
                    authenticationBox: authContext.mastodonAuthenticationBox
                )
            case false:
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
        logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): \(indexPath)")
        tableView.deselectRow(at: indexPath, animated: true)

        let object = fetchedResultsController.records[indexPath.row]

        let hashtagTimelineViewModel = HashtagTimelineViewModel(
            context: self.context,
            authContext: self.authContext,
            hashtag: object.name
        )
        
        presentHashtagTimeline.send(hashtagTimelineViewModel)
    }
}
