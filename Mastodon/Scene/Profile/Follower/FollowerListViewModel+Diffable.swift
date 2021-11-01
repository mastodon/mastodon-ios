//
//  FollowerListViewModel+Diffable.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-11-1.
//

import UIKit

extension FollowerListViewModel {
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency
    ) {
        diffableDataSource = UserSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            managedObjectContext: userFetchedResultsController.fetchedResultsController.managedObjectContext
        )
        
        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        // workaround to append loader wrong animation issue
        snapshot.appendItems([.bottomLoader], toSection: .main)
        diffableDataSource?.apply(snapshot)
        
        userFetchedResultsController.objectIDs.removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] objectIDs in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }
                
                var snapshot = NSDiffableDataSourceSnapshot<UserSection, UserItem>()
                snapshot.appendSections([.main])
                let items: [UserItem] = objectIDs.map {
                    UserItem.follower(objectID: $0)
                }
                snapshot.appendItems(items, toSection: .main)
                
                if let currentState = self.stateMachine.currentState {
                    switch currentState {
                    case is State.Idle, is State.Loading, is State.Fail:
                        snapshot.appendItems([.bottomLoader], toSection: .main)
                    case is State.NoMore:
                        break
                    default:
                        break
                    }
                }
                
                diffableDataSource.apply(snapshot)
            }
            .store(in: &disposeBag)
    }
}
