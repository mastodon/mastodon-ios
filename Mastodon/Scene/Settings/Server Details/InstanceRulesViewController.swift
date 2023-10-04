// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

protocol InstanceRulesViewControllerDelegate: AnyObject {

}

class InstanceRulesViewController: UIViewController {

    weak var delegate: InstanceRulesViewControllerDelegate?
    let tableView: UITableView
    var dataSource: UITableViewDiffableDataSource<ServerRuleSection, ServerRuleItem>?

    var sections: [ServerRuleSection] = []

    init() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ServerRulesTableViewCell.self, forCellReuseIdentifier: ServerRulesTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)
        view.addSubview(tableView)

        let dataSource = ServerRuleSection.tableViewDiffableDataSource(tableView: tableView)

        tableView.dataSource = dataSource
        self.dataSource = dataSource

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    func update(with instance: Mastodon.Entity.V2.Instance) {
        guard let dataSource, let rules = instance.rules, rules.isNotEmpty else { return }

        var snapshot = NSDiffableDataSourceSnapshot<ServerRuleSection, ServerRuleItem>()

        snapshot.appendSections([.rules])
        let ruleItems = rules.enumerated().compactMap { index, rule in ServerRuleItem.rule(index: index, rule: rule) }
        snapshot.appendItems(ruleItems, toSection: .rules)

        dataSource.apply(snapshot)
    }
}
