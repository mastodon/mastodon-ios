// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

protocol PolicySelectionViewControllerDelegate: AnyObject {
    func newPolicySelected(_ viewController: PolicySelectionViewController, newPolicy: NotificationPolicy)
}

class PolicySelectionViewController: UIViewController {

    weak var delegate: PolicySelectionViewControllerDelegate?

    let tableView: UITableView
    var dataSource: UITableViewDiffableDataSource<NotificationPolicySection, NotificationPolicy>?

    var viewModel: NotificationSettingsViewModel
    let sections = [NotificationPolicySection(entries: NotificationPolicy.allCases)]

    init(viewModel: NotificationSettingsViewModel) {

        self.viewModel  = viewModel
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationPolicyTableViewCell.self, forCellReuseIdentifier: NotificationPolicyTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        let dataSource = UITableViewDiffableDataSource<NotificationPolicySection, NotificationPolicy>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in

            guard let self, let cell = tableView.dequeueReusableCell(withIdentifier: NotificationPolicyTableViewCell.reuseIdentifier, for: indexPath) as? NotificationPolicyTableViewCell else {
                assertionFailure("unexpected cell dequeued")
                return nil
            }

            let policy = self.sections[indexPath.section].entries[indexPath.row]
            cell.configure(with: policy, selectedPolicy: self.viewModel.selectedPolicy)

            return cell
        }

        view.addSubview(tableView)
        view.backgroundColor = .systemGroupedBackground

        tableView.pinToParent()
        tableView.delegate = self
        tableView.dataSource = dataSource

        self.dataSource = dataSource
        title = L10n.Scene.Settings.Notifications.Policy.title
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        var snapshot = NSDiffableDataSourceSnapshot<NotificationPolicySection, NotificationPolicy>()
        snapshot.appendSections(sections)
        snapshot.appendItems(NotificationPolicy.allCases)

        dataSource?.apply(snapshot)
    }
}

extension PolicySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let newPolicy = sections[indexPath.section].entries[indexPath.row]
        viewModel.selectedPolicy = newPolicy
        viewModel.updated = true

        if let dataSource {
            dataSource.applySnapshotUsingReloadData(dataSource.snapshot())
        }

        delegate?.newPolicySelected(self, newPolicy: newPolicy)

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
