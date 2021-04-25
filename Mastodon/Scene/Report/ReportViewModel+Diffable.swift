//
//  ReportViewModel+Diffable.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/19.
//

import UIKit
import Combine
import CoreData
import CoreDataStack

extension ReportViewModel {
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: ReportViewController
    ) {
        let timestampUpdatePublisher = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .share()
            .eraseToAnyPublisher()
        
        diffableDataSource = ReportSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            managedObjectContext: statusFetchedResultsController.fetchedResultsController.managedObjectContext,
            timestampUpdatePublisher: timestampUpdatePublisher
        )
        
        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<ReportSection, Item>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
    }
}
