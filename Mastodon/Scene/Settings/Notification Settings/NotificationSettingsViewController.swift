// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import Combine
import CoreDataStack
import MastodonLocalization
import MastodonCore

protocol NotificationSettingsViewControllerDelegate: AnyObject {
    func viewWillDisappear(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel)
    func showPolicyList(_ viewController: UIViewController, viewModel: NotificationSettingsViewModel)
    func showNotificationSettings(_ viewController: UIViewController)
}

class NotificationSettingsViewController: UIViewController {

    weak var delegate: NotificationSettingsViewControllerDelegate?

    let tableView: UITableView
    var tableViewDataSource: UITableViewDiffableDataSource<NotificationSettingsSection, NotificationSettingEntry>?
    
    var isNotificationPermissionGranted = NotificationService.shared.isNotificationPermissionGranted.value

    var sections: [NotificationSettingsSection] = []
    var viewModel: NotificationSettingsViewModel
    
    var disposeBag = Set<AnyCancellable>()

    init(authBox: MastodonAuthenticationBox) {
        viewModel = NotificationSettingsViewModel(authBox: authBox)

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NotificationSettingTableViewCell.self, forCellReuseIdentifier: NotificationSettingTableViewCell.reuseIdentifier)
        tableView.register(NotificationSettingTableViewToggleCell.self, forCellReuseIdentifier: NotificationSettingTableViewToggleCell.reuseIdentifier)
        tableView.register(NotificationSettingsDisabledTableViewCell.self, forCellReuseIdentifier: NotificationSettingsDisabledTableViewCell.reuseIdentifier)
        
        super.init(nibName: nil, bundle: nil)
        
        NotificationService.shared.isNotificationPermissionGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] granted in
                self?.reloadTableview(notificationsAllowed: granted)
            }
            .store(in: &disposeBag)
        
        let tableViewDataSource = UITableViewDiffableDataSource<NotificationSettingsSection, NotificationSettingEntry>(tableView: tableView) { [ weak self] tableView, indexPath, itemIdentifier in

            let cell: UITableViewCell

            switch itemIdentifier {
                case .notificationDisabled:
                    guard let notificationsDisabledCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingsDisabledTableViewCell.reuseIdentifier, for: indexPath) as? NotificationSettingsDisabledTableViewCell else { fatalError("WTF Wrong cell!?") }

                    cell = notificationsDisabledCell

                case .policy:
                    guard let self,
                          let notificationCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingTableViewCell.reuseIdentifier, for: indexPath) as? NotificationSettingTableViewCell else { fatalError("WTF Wrong cell!?") }

                    notificationCell.configure(with: .policy, viewModel: self.viewModel, notificationsEnabled: isNotificationPermissionGranted)
                    cell = notificationCell

                case .alert(let alert):
                    guard let self,
                          let toggleCell = tableView.dequeueReusableCell(withIdentifier: NotificationSettingTableViewToggleCell.reuseIdentifier, for: indexPath) as? NotificationSettingTableViewToggleCell else { fatalError("WTF Wrong cell!?") }
                    
                    toggleCell.configure(with: alert, viewModel: self.viewModel, notificationsEnabled: isNotificationPermissionGranted)
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

        if AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.count > 1, let username = AuthenticationServiceProvider.shared.currentActiveUser.value?.cachedAccount?.acctWithDomain {
            title = username
        } else {
            title = L10n.Scene.Settings.Notifications.title
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        reloadTableview(notificationsAllowed: isNotificationPermissionGranted)
        checkIfPermissionGranted()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkIfPermissionGranted()
    }
    
    @objc func willEnterForeground() {
        checkIfPermissionGranted()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        delegate?.viewWillDisappear(self, viewModel: viewModel)
    }
    
    func checkIfPermissionGranted() {
        NotificationService.shared.requestUpdate(.allAccounts)
    }
    
    func reloadTableview(notificationsAllowed: Bool) {
        guard viewIfLoaded != nil else { return }
        isNotificationPermissionGranted = notificationsAllowed
        if notificationsAllowed {
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
        
        var snapshot = NSDiffableDataSourceSnapshot<NotificationSettingsSection, NotificationSettingEntry>()
        
        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.entries)
        }
        
        tableViewDataSource?.applySnapshotUsingReloadData(snapshot)
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
        viewModel.updatePushNotifications(forType: alert, newValue: newValue)
    }
}
