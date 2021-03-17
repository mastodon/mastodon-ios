//
//  ComposeViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-11.
//

import UIKit
import TwitterTextEditor

extension ComposeViewModel {
    
    func setupDiffableDataSource(
        for tableView: UITableView,
        dependency: NeedsDependency,
        textEditorViewTextAttributesDelegate: TextEditorViewTextAttributesDelegate
    ) {
        diffableDataSource = ComposeStatusSection.tableViewDiffableDataSource(
            for: tableView,
            dependency: dependency,
            managedObjectContext: context.managedObjectContext,
            composeKind: composeKind,
            textEditorViewTextAttributesDelegate: textEditorViewTextAttributesDelegate
        )
        
        var snapshot = NSDiffableDataSourceSnapshot<ComposeStatusSection, ComposeStatusItem>()
        snapshot.appendSections([.repliedTo, .status, .attachment])
        switch composeKind {
        case .reply(let statusObjectID):
            snapshot.appendItems([.replyTo(statusObjectID: statusObjectID)], toSection: .repliedTo)
            snapshot.appendItems([.input(replyToStatusObjectID: statusObjectID, attribute: composeStatusAttribute)], toSection: .repliedTo)
        case .post:
            snapshot.appendItems([.input(replyToStatusObjectID: nil, attribute: composeStatusAttribute)], toSection: .status)
        }
        diffableDataSource.apply(snapshot, animatingDifferences: false)
    }
    
}
