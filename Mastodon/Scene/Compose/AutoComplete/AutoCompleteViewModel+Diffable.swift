//
//  AutoCompleteViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-17.
//

import UIKit

extension AutoCompleteViewModel {
    
    func setupDiffableDataSource(
        for tableView: UITableView
    ) {
        diffableDataSource = AutoCompleteSection.tableViewDiffableDataSource(for: tableView)
        
        var snapshot = NSDiffableDataSourceSnapshot<AutoCompleteSection, AutoCompleteItem>()
        snapshot.appendSections([.main])
        diffableDataSource?.apply(snapshot)
    }
    
}
