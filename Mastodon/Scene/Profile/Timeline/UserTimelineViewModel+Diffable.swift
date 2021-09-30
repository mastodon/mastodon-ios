//
//  UserTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit

extension UserTimelineViewModel {
 
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) {
        diffableDataSource = StatusSection.tableViewDiffableDataSource(
            for: tableView,
            timelineContext: .account,
            dependency: dependency,
            managedObjectContext: statusFetchedResultsController.fetchedResultsController.managedObjectContext,
            statusTableViewCellDelegate: statusTableViewCellDelegate,
            timelineMiddleLoaderTableViewCellDelegate: nil,
            threadReplyLoaderTableViewCellDelegate: nil
        )
        
        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, Item>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)

        // workaround to append loader wrong animation issue
        snapshot.appendItems([.bottomLoader], toSection: .main)
        diffableDataSource?.apply(snapshot)
    }
    
}
