// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

protocol SettingsViewControllerDelegate: AnyObject {
    func done(_ viewController: UIViewController)
    func didSelect(_ viewController: UIViewController, entry: SettingsEntry)
}

class SettingsViewController: UIViewController {

    let sections: [SettingsSection]

    weak var delegate: SettingsViewControllerDelegate?
    var tableViewDataSource: UITableViewDiffableDataSource<SettingsSection, SettingsEntry>?
    let tableView: UITableView

    init(accountName: String, domain: String) {

        sections = [
            .init(entries: [.general, .notifications, .privacySafety]),
            .init(entries: [.serverDetails(domain: domain), .aboutMastodon]),
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(SettingsViewController.done(_:)))

        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)

        title = L10n.Scene.Settings.Overview.title

        tableView.pinToParent()
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
