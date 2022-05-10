//
//  ReportSupplementaryViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-7.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonAsset
import MastodonLocalization

extension ReportSupplementaryViewModel {
    
    static let reportItemHeaderContext = ReportItem.HeaderContext(
        primaryLabelText: "Is there anything else we should know?",
        secondaryLabelText: "Step 4 of 4"
    )
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = ReportSection.diffableDataSource(
            tableView: tableView,
            context: context,
            configuration: ReportSection.Configuration()
        )

        var snapshot = NSDiffableDataSourceSnapshot<ReportSection, ReportItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems([.header(context: ReportSupplementaryViewModel.reportItemHeaderContext)], toSection: .main)
        snapshot.appendItems([.comment(context: commentContext)], toSection: .main)
        
        diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }
}
