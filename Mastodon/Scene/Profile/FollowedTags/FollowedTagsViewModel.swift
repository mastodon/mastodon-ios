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
    
    // input
    let context: AppContext
    let authContext: AuthContext
    
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
            .sink { [weak self] _ in
                self?.tableView?.reloadSections(IndexSet(integer: 0), with: .automatic)
            }
            .store(in: &disposeBag)
    }
}

extension FollowedTagsViewModel {
    func setupTableView(_ tableView: UITableView) {
        self.tableView = tableView
        tableView.dataSource = self
        tableView.delegate = self
        
        fetchFollowedTags {
            tableView.reloadData()
        }
    }
    
    func fetchFollowedTags(_ done: @escaping () -> Void) {
        Task { @MainActor [weak self] in
            try? await self?._fetchFollowedTags()
            done()
        }
    }
    
    private func _fetchFollowedTags() async throws {
        try await context.apiService.getFollowedTags(
            domain: authContext.mastodonAuthenticationBox.domain,
            query: Mastodon.API.Account.FollowedTagsQuery(limit: nil),
            authenticationBox: authContext.mastodonAuthenticationBox
        )
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
            try? await _fetchFollowedTags()
        }
    }
}

extension FollowedTagsViewModel: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fetchedResultsController.records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            indexPath.section == 0,
            let object = fetchedResultsController.records[indexPath.row].object(in: context.managedObjectContext)
        else {
            return UITableViewCell()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FollowedTagsTableViewCell.self), for: indexPath) as! FollowedTagsTableViewCell

        cell.setup(self)
        cell.populate(with: object)
        return cell
    }
}

extension FollowedTagsViewModel: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
