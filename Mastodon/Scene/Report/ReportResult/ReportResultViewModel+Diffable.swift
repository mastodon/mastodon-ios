//
//  ReportResultViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-8.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonAsset
import MastodonLocalization

extension ReportResultViewModel {
    
    static let reportItemHeaderContext = ReportItem.HeaderContext(
        primaryLabelText: "Thanks for reporting, we’ll look into this.",
        secondaryLabelText: ""
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
        snapshot.appendItems([.header(context: ReportResultViewModel.reportItemHeaderContext)], toSection: .main)
        snapshot.appendItems([.result(record: user)], toSection: .main)
        diffableDataSource?.apply(snapshot)
    }
}
