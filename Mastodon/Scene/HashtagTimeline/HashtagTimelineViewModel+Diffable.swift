//
//  HashtagTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by BradGao on 2021/3/30.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack

extension HashtagTimelineViewModel {
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) {
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: StatusSection.Configuration(
                statusTableViewCellDelegate: statusTableViewCellDelegate,
                timelineMiddleLoaderTableViewCellDelegate: nil,
                filterContext: .none,
                activeFilters: nil
            )
        )

        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)

        fetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                self.logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): incoming \(records.count) objects")
                
                var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
                snapshot.appendSections([.main])
                let items = records.map { StatusItem.status(record: $0) }
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.loadOldestStateMachine.currentState {
                    switch currentState {
                    case is LoadOldestState.Initial,
                        is LoadOldestState.Loading,
                        is LoadOldestState.Idle,
                        is LoadOldestState.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    case is LoadOldestState.NoMore:
                        break
                    default:
                        assertionFailure()
                        break
                    }
                }
                
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
}
