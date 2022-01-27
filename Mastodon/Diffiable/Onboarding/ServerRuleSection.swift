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
    case header
    case rules
}

extension ServerRuleSection {
    static func tableViewDiffableDataSource(
        tableView: UITableView
    ) -> UITableViewDiffableDataSource<ServerRuleSection, ServerRuleItem> {
        return UITableViewDiffableDataSource(tableView: tableView) { tableView, indexPath, item in
            switch item {
            case .header(let domain):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: OnboardingHeadlineTableViewCell.self), for: indexPath) as! OnboardingHeadlineTableViewCell
                cell.titleLabel.text = L10n.Scene.ServerRules.title
                cell.subTitleLabel.text = L10n.Scene.ServerRules.subtitle(domain)
                return cell
            case .rule(let ruleContext):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: ServerRulesTableViewCell.self), for: indexPath) as! ServerRulesTableViewCell
                cell.indexImageView.image = UIImage(systemName: "\(ruleContext.index + 1).circle.fill") ?? UIImage(systemName: "questionmark.circle.fill")
                cell.ruleLabel.text = ruleContext.rule.text
                return cell
            }
        }
    }
}
