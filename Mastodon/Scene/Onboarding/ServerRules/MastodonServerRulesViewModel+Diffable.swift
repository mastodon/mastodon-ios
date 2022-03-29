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
        snapshot.appendSections([.header, .rules])
        snapshot.appendItems([.header(domain: domain)], toSection: .header)
        let ruleItems: [ServerRuleItem] = rules.enumerated().map { i, rule in
            let ruleContext = ServerRuleItem.RuleContext(index: i, rule: rule)
            return ServerRuleItem.rule(ruleContext)
        }
        snapshot.appendItems(ruleItems, toSection: .rules)
        diffableDataSource?.applySnapshot(snapshot, animated: false, completion: nil)
    }
}
