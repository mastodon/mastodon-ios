//
//  ComposeViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit

extension ComposeViewModel {
    
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency
    ) {
        diffableDataSource = ComposeStatusSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            managedObjectContext: context.managedObjectContext,
            composeKind: composeKind
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusSection, ComposeStatusItem>()
        snapshot.appendSections([.repliedTo, .status])
        switch composeKind {
        case .replyToot(let tootObjectID):
            snapshot.appendItems([.replyTo(tootObjectID: tootObjectID)], toSection: .repliedTo)
            snapshot.appendItems([.toot(replyToTootObjectID: tootObjectID, attribute: composeTootAttribute)], toSection: .status)
        case .toot:
            snapshot.appendItems([.toot(replyToTootObjectID: nil, attribute: composeTootAttribute)], toSection: .status)
        }
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
    
}
