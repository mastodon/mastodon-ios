// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

struct SettingsSection: Hashable {
    let entries: [SettingsEntry]
}

enum SettingsEntry: Hashable {
    case general
    case notifications
    case aboutMastodon
    case supportMastodon
    case logout(accountName: String)

    //TODO: @zeitschlag Add Localization
    var title: String {
        switch self {
        case .general:
            return "General"
        case .notifications:
            return "Notifications"
        case .aboutMastodon:
            return "About Mastodon"
        case .supportMastodon:
            return "Support Mastodon"
        case .logout(let accountName):
            return "Logout @\(accountName)"
        }
    }

    var accessoryType: UITableViewCell.AccessoryType {
        switch self {
        case .general, .notifications, .aboutMastodon, .logout(_):
            return .disclosureIndicator
        case .supportMastodon:
            return .none
        }
    }

    var icon: UIImage? {
        switch self {
        case .general:
            return UIImage(systemName: "gear")
        case .notifications:
            return UIImage(systemName: "bell.badge")
        case .aboutMastodon:
            return UIImage(systemName: "info.circle.fill")
        case .supportMastodon:
            return UIImage(systemName: "heart.fill")
        case .logout(_):
            return nil
        }
    }

    var iconBackgroundColor: UIColor? {
        switch self {
        case .general:
            return .systemGray
        case .notifications:
            return .systemRed
        case .aboutMastodon:
            return .systemPurple
        case .supportMastodon:
            return .systemGreen
        case .logout(_):
            return nil
        }

    }

    var textColor: UIColor {
        switch self {
        case .general, .notifications, .aboutMastodon, .supportMastodon:
            return .label
        case .logout(_):
            return .red
        }

    }
}

protocol SettingsViewControllerDelegate: AnyObject {
    func done(_ viewController: UIViewController)
    func didSelect(_ viewController: UIViewController, entry: SettingsEntry)
}

class SettingsViewController: UIViewController {

    let sections: [SettingsSection]

    weak var delegate: SettingsViewControllerDelegate?
    var tableViewDataSource: UITableViewDiffableDataSource<SettingsSection, SettingsEntry>?
    let tableView: UITableView

    init(accountName: String) {

        sections = [
           .init(entries: [.general, .notifications]),
           .init(entries: [.supportMastodon, .aboutMastodon]),
           .init(entries: [.logout(accountName: accountName)])
       ]

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(SettingsTableViewCell.self, forCellReuseIdentifier: SettingsTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        let tableViewDataSource = UITableViewDiffableDataSource<SettingsSection, SettingsEntry>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
            guard let self,
                  let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.reuseIdentifier, for: indexPath) as? SettingsTableViewCell
            else { fatalError("Wrong cell WTF??") }

            let entry = self.sections[indexPath.section].entries[indexPath.row]
            cell.update(with: entry)

            return cell
        }

        tableView.dataSource = tableViewDataSource
        tableView.delegate = self
        self.tableViewDataSource = tableViewDataSource

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(SettingsViewController.done(_:)))

        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)

        title = "Settings"

        setupConstraints()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsEntry>()

        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.entries)
        }

        tableViewDataSource?.apply(snapshot)
    }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.bottomAnchor),
        ]

        NSLayoutConstraint.activate(constraints)
    }

    //MARK: Actions

    @objc
    func done(_ sender: Any) {
        delegate?.done(self)
    }
}

//MARK: UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let entry = sections[indexPath.section].entries[indexPath.row]

        delegate?.didSelect(self, entry: entry)

        tableView.deselectRow(at: indexPath, animated: true)
    }
}
