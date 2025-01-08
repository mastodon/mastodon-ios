// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import CoreDataStack
import MastodonLocalization

protocol NotificationSettingsViewControllerDelegate: AnyObject {
    func viewWillDisappear(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel)
    func showPolicyList(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel)
    func showNotificationSettings(_ viewController: UIViewController)
}

class NotificationSettingsViewController: UIViewController {

    weak var delegate: NotificationSettingsViewControllerDelegate?

    let tableView: UITableView
    var tableViewDataSource: UITableViewDiffableDataSource<NotificationSettingsSection, NotificationSettingEntry>?

    let sections: [NotificationSettingsSection]
    var viewModel: NotificationSettingsViewModel

    init(currentSetting: Setting?, notificationsEnabled: Bool) {
        let activeSubscription = currentSetting?.activeSubscription
        let alert = activeSubscription?.alert
        viewModel = NotificationSettingsViewModel(selectedPolicy: activeSubscription?.notificationPolicy ?? .noone,
                                                  notifyMentions: alert?.mention ?? false,
                                                  notifyBoosts: alert?.reblog ?? false,
                                                  notifyFavorites: alert?.favourite ?? false,
                                                  notifyNewFollowers: alert?.follow ?? false)

        if notificationsEnabled {
            sections = [
                NotificationSettingsSection(entries: [.policy]),
                NotificationSettingsSection(entries: NotificationAlert.allCases.map { NotificationSettingEntry.alert($0) } )
            ]
        } else {
            sections = [
                NotificationSettingsSection(entries: [.notificationDisabled]),
                NotificationSettingsSection(entries: [.policy]),
                NotificationSettingsSection(entries: NotificationAlert.allCases.map { NotificationSettingEntry.alert($0) } )
            ]
        }

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationSettingTableViewCell.self, forCellReuseIdentifier: NotificationSettingTableViewCell.reuseIdentifier)
        tableView.register(NotificationSettingTableViewToggleCell.self, forCellReuseIdentifier: NotificationSettingTableViewToggleCell.reuseIdentifier)
        tableView.register(NotificationSettingsDisabledTableViewCell.self, forCellReuseIdentifier: NotificationSettingsDisabledTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        let tableViewDataSource = UITableViewDiffableDataSource<NotificationSettingsSection, NotificationSettingEntry>(tableView: tableView) { [ weak self] tableView, indexPath, itemIdentifier in

            let cell: UITableViewCell

            switch itemIdentifier {
                case .notificationDisabled:
                guard let notificationsDisabledCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingsDisabledTableViewCell.reuseIdentifier, for: indexPath) as? NotificationSettingsDisabledTableViewCell else {
                    assertionFailure("unexpected cell dequeued")
                    return nil
                }

                    cell = notificationsDisabledCell

                case .policy:
                    guard let self,
                          let notificationCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingTableViewCell.reuseIdentifier, for: indexPath) as? NotificationSettingTableViewCell else {
                        assertionFailure("unexpected cell dequeued")
                        return nil
                    }

                    notificationCell.configure(with: .policy, viewModel: self.viewModel, notificationsEnabled: notificationsEnabled)
                    cell = notificationCell

                case .alert(let alert):
                    guard let self,
                          let toggleCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingTableViewToggleCell.reuseIdentifier, for: indexPath) as? NotificationSettingTableViewToggleCell else {
                        assertionFailure("unexpected cell dequeued")
                        return nil
                    }

                    toggleCell.configure(with: alert, viewModel: self.viewModel, notificationsEnabled: notificationsEnabled)
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

        title = L10n.Scene.Settings.Notifications.title
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let snapshot = tableViewDataSource?.snapshot() {
            tableViewDataSource?.applySnapshotUsingReloadData(snapshot)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        delegate?.viewWillDisappear(self, viewModel: viewModel)
    }
}

extension NotificationSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let entry = sections[indexPath.section].entries[indexPath.row]
        switch entry {
            case .alert(let alert):

                guard let cell = tableView.cellForRow(at: indexPath) as? NotificationSettingTableViewToggleCell else { return }

                let newValue = (cell.toggle.isOn == false)
                cell.toggle.setOn(newValue, animated: true)

                toggleValueChanged(cell, alert: alert, newValue: newValue)

            case .policy:
                delegate?.showPolicyList(self, viewModel: viewModel)
            case .notificationDisabled:
                delegate?.showNotificationSettings(self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension NotificationSettingsViewController: NotificationSettingToggleCellDelegate {
    func toggleValueChanged(_ tableViewCell: NotificationSettingTableViewToggleCell, alert: NotificationAlert, newValue: Bool) {
        switch alert {
            case .mentionsAndReplies:
                viewModel.notifyMentions = newValue
            case .boosts:
                viewModel.notifyBoosts = newValue
            case .favorites:
                viewModel.notifyFavorites = newValue
            case .newFollowers:
                viewModel.notifyNewFollowers = newValue
        }

        viewModel.updated = true
    }
}
