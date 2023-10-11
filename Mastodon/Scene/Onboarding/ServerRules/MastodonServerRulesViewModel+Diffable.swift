//
//  MastodonServerRulesViewModel+Diffable.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import UIKit

extension MastodonServerRulesViewModel {
    func setupDiffableDataSource(
        tableView: UITableView
    ) {
        diffableDataSource = ServerRuleSection.tableViewDiffableDataSource(tableView: tableView)
        
        var snapshot = NSDiffableDataSourceSnapshot<ServerRuleSection, ServerRuleItem>()
        snapshot.appendSections([.rules])
        let ruleItems: [ServerRuleItem] = rules.enumerated().map { index, rule in return ServerRuleItem.rule(index: index, rule: rule) }
        snapshot.appendItems(ruleItems, toSection: .rules)
        diffableDataSource?.apply(snapshot, animatingDifferences: false)
    }
}
