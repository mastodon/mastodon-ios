// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

protocol NotificationSettingsViewControllerDelegate: AnyObject {
    func showPolicyList(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel)
}

class NotificationSettingsViewController: UIViewController {

    weak var delegate: NotificationSettingsViewControllerDelegate?

    let tableView: UITableView
    var tableViewDataSource: UITableViewDiffableDataSource<NotificationSettingsSection, NotificationSettingEntry>?

    let sections: [NotificationSettingsSection]
    var viewModel: NotificationSettingsViewModel

    init() {

        //TODO: @zeitschlag Read Settings
        viewModel = NotificationSettingsViewModel(selectedPolicy: .follow)
        sections = [
            NotificationSettingsSection(entries: [
                .policy
            ]),
            NotificationSettingsSection(entries: NotificationAlert.allCases.map { NotificationSettingEntry.alert($0) } )
        ]

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationSettingTableViewCell.self, forCellReuseIdentifier: NotificationSettingTableViewCell.reuseIdentifier)
        tableView.register(NotificationSettingTableViewToggleCell.self, forCellReuseIdentifier: NotificationSettingTableViewToggleCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        let tableViewDataSource = UITableViewDiffableDataSource<NotificationSettingsSection, NotificationSettingEntry>(tableView: tableView) { [ weak self] tableView, indexPath, itemIdentifier in

            let cell: UITableViewCell

            switch itemIdentifier {
            case .policy:
                guard let self,
                      let notificationCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingTableViewCell.reuseIdentifier, for: indexPath) as? NotificationSettingTableViewCell else { fatalError("WTF Wrong cell!?") }

                notificationCell.configure(with: .policy, viewModel: self.viewModel)
                cell = notificationCell

            case .alert(let alert):
                guard let self,
                      let toggleCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingTableViewToggleCell.reuseIdentifier, for: indexPath) as? NotificationSettingTableViewToggleCell else { fatalError("WTF Wrong cell!?") }

                toggleCell.configure(with: alert, viewModel: self.viewModel)
                toggleCell.delegate = self
                cell = toggleCell
            }

            return cell
        }

        tableView.dataSource = tableViewDataSource
        tableView.delegate = self
        self.tableViewDataSource = tableViewDataSource

        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        tableView.pinToParent()

        title = "Notifications"
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<NotificationSettingsSection, NotificationSettingEntry>()

        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.entries)
        }

        tableViewDataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension NotificationSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let entry = sections[indexPath.section].entries[indexPath.row]

        if case let .policy = entry {
            delegate?.showPolicyList(self, viewModel: viewModel)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NotificationSettingsViewController: NotificationSettingToggleCellDelegate {
    
}
