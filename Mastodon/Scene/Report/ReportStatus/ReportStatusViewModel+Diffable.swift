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
import MastodonAsset
import MastodonLocalization

extension ReportStatusViewModel {
    
    static let reportItemHeaderContext = ReportItem.HeaderContext(
        primaryLabelText: L10n.Scene.Report.content1,
        secondaryLabelText: L10n.Scene.Report.StepThree.step3Of4
    )
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = ReportSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: ReportSection.Configuration(authContext: authContext)
        )

        var snapshot = NSDiffableDataSourceSnapshot<ReportSection, ReportItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
        
        statusFetchedResultsController.$records
            .receive(on: DispatchQueue.main)
            .sink { [weak self] records in
                guard let self = self else { return }
                guard let diffableDataSource = self.diffableDataSource else { return }

                var snapshot = NSDiffableDataSourceSnapshot<ReportSection, ReportItem>()
                snapshot.appendSections([.main])
                
                snapshot.appendItems([.header(context: ReportStatusViewModel.reportItemHeaderContext)], toSection: .main)
                
                let items = records.map { ReportItem.status(record: $0) }
                snapshot.appendItems(items, toSection: .main)
                
                let selectItems = items.filter { item in
                    guard case let .status(record) = item else { return false }
                    return self.selectStatuses.contains(record)
                }
                
                guard let currentState = self.stateMachine.currentState else { return }
                switch currentState {
                case is State.Initial,
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
                
                diffableDataSource.applySnapshot(snapshot, animated: false) { [weak self] in
                    guard let self = self else { return }
                    guard let diffableDataSource = self.diffableDataSource else { return }
                    
                    let selectIndexPaths = selectItems.compactMap { item in
                        diffableDataSource.indexPath(for: item)
                    }
                        
                    // Only the first selection make the initial selection
                    // The later selection could be ignored
                    for indexPath in selectIndexPaths {
                        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                    }
                }
            }
            .store(in: &disposeBag)
    }
}
