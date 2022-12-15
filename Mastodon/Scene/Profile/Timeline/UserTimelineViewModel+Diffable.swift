//
//  UserTimelineViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-30.
//

import UIKit
import Combine

extension UserTimelineViewModel {
 
    func setupDiffableDataSource(
        tableView: UITableView,
        statusTableViewCellDelegate: StatusTableViewCellDelegate
    ) {
        diffableDataSource = StatusSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: StatusSection.Configuration(
                context: context,
                authContext: authContext,
                statusTableViewCellDelegate: statusTableViewCellDelegate,
                timelineMiddleLoaderTableViewCellDelegate: nil,
                filterContext: .none,
                activeFilters: nil
            )
        )

        // set empty section to make update animation top-to-bottom style
        var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        // trigger timeline reloading
        $userIdentifier
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.stateMachine.enter(UserTimelineViewModel.State.Reloading.self)
            }
            .store(in: &disposeBag)
        
        let needsTimelineHidden = Publishers.CombineLatest3(
            $isBlocking,
            $isBlockedBy,
            $isSuspended
        ).map { $0 || $1 || $2 }
        
        Publishers.CombineLatest(
            statusFetchedResultsController.$records,
            needsTimelineHidden.removeDuplicates()
        )
        .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
        .sink { [weak self] records, needsTimelineHidden in
            guard let self = self else { return }
            guard let diffableDataSource = self.diffableDataSource else { return }
            
            var snapshot = NSDiffableDataSourceSnapshot<StatusSection, StatusItem>()
            snapshot.appendSections([.main])
            
            guard !needsTimelineHidden else {
                diffableDataSource.apply(snapshot)
                return
            }

            let items = records.map { StatusItem.status(record: $0) }
            snapshot.appendItems(items, toSection: .main)
            
            if let currentState = self.stateMachine.currentState {
                switch currentState {
                case is State.Initial,
                    is State.Reloading,
                    is State.Loading,
                    is State.Idle,
                    is State.Fail:
                    snapshot.appendItems([.bottomLoader], toSection: .main)
                case is State.NoMore:
                    break
                default:
                    assertionFailure()
                    break
                }
            }
            
            diffableDataSource.applySnapshot(snapshot, animated: false)
        }
        .store(in: &disposeBag)
    }
    
}
