//
//  ServerRuleSection.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import UIKit
import MastodonAsset
import MastodonLocalization

enum ServerRuleSection: Hashable {
    case rules
}

extension ServerRuleSection {
    static func tableViewDiffableDataSource(
        tableView: UITableView
    ) -> UITableViewDiffableDataSource<ServerRuleSection, ServerRuleItem> {
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .rule(let ruleContext):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ServerRulesTableViewCell.self), for: indexPath) as! ServerRulesTableViewCell
                cell.indexImageView.image = UIImage(systemName: "\(ruleContext.index + 1).circle") ?? UIImage(systemName: "questionmark.circle")
                cell.indexImageView.tintColor = Asset.Colors.brand.color
                cell.ruleLabel.text = ruleContext.rule.text
                return cell
            }
        }
    }
}
