// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonCore
import MastodonLocalization

protocol AboutViewControllerDelegate: AnyObject {
    func didSelect(_ viewController: AboutViewController, entry: AboutSettingsEntry)
}

class AboutViewController: UIViewController {

    let tableView: UITableView
    private(set) var sections: [AboutSettingsSection] = []
    var tableViewDataSource: UITableViewDiffableDataSource<AboutSettingsSection, AboutSettingsEntry>?
    weak var delegate: AboutViewControllerDelegate?

    init() {

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AboutMastodonTableViewCell.self, forCellReuseIdentifier: AboutMastodonTableViewCell.reuseIdentifier)

        super.init(nibName: nil, bundle: nil)

        let tableViewDataSource = UITableViewDiffableDataSource<AboutSettingsSection, AboutSettingsEntry>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in

            guard let self,
                    let cell = tableView.dequeueReusableCell(withIdentifier: AboutMastodonTableViewCell.reuseIdentifier, for: indexPath) as? AboutMastodonTableViewCell else { fatalError("WTF?? Wrong Cell dude!") }

            let entry = sections[indexPath.section].entries[indexPath.row]
            cell.configure(with: entry)

            return cell
        }

        tableView.delegate = self
        tableView.dataSource = tableViewDataSource
        self.tableViewDataSource = tableViewDataSource

        view.addSubview(tableView)
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Scene.Settings.AboutMastodon.title

        tableView.pinToParent()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        update(with:
                [AboutSettingsSection(entries: [
                    .evenMoreSettings,
                    .contributeToMastodon,
                    .privacyPolicy
                ]),
                 AboutSettingsSection(entries: [
                    .clearMediaCache(AppContext.shared.currentDiskUsage())
                 ])]
        )
    }

    func update(with sections: [AboutSettingsSection]) {
        self.sections = sections

        var snapshot = NSDiffableDataSourceSnapshot<AboutSettingsSection, AboutSettingsEntry>()

        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.entries)
        }

        tableViewDataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension AboutViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let entry = sections[indexPath.section].entries[indexPath.row]
        delegate?.didSelect(self, entry: entry)

        tableView.deselectRow(at: indexPath, animated: true)
    }
}

