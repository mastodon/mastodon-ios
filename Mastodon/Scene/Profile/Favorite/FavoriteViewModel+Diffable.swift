//
//  FavoriteViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-7.
//

import UIKit

extension FavoriteViewModel {
    
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) {
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        diffableDataSource = StatusSection.tableViewDiffableDataSource(
            for: tableView,
            timelineContext: .favorite,
            dependency: dependency,
            managedObjectContext: statusFetchedResultsController.fetchedResultsController.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher,
            statusTableViewCellDelegate: statusTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil,
            threadReplyLoaderTableViewCellDelegate: nil
        )
        
        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        stateMachine.enter(State.Reloading.self)
    }
    
}
