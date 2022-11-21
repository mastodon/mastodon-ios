//
//  AutoCompleteViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-17.
//

import UIKit
import MastodonCore

extension AutoCompleteViewModel {
    
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = AutoCompleteSection.tableViewDiffableDataSource(tableView: tableView)

        var snapshot = NSDiffableDataSourceSnapshot<AutoCompleteSection, AutoCompleteItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
    }
    
}
