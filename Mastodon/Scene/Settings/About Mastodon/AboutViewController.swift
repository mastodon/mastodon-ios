// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonCore
import MastodonLocalization
import MastodonAsset

protocol AboutViewControllerDelegate: AnyObject {
    func didSelect(_ viewController: AboutViewController, entry: AboutSettingsEntry)
}

class AboutViewController: UIViewController {

    let tableView: UITableView
    let tableFooterView: UIView
    let versionLabel: UILabel

    private(set) var sections: [AboutSettingsSection] = []
    var tableViewDataSource: UITableViewDiffableDataSource<AboutSettingsSection, AboutSettingsEntry>?
    weak var delegate: AboutViewControllerDelegate?

    init() {

        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(AboutMastodonTableViewCell.self, forCellReuseIdentifier: AboutMastodonTableViewCell.reuseIdentifier)

        versionLabel = UILabel()
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        versionLabel.text = "Mastodon for iOS v\(UIApplication.appVersion()) (\(UIApplication.appBuild()))"
        versionLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 12, weight: .regular))
        versionLabel.textColor = Asset.Colors.Label.secondary.color
        versionLabel.numberOfLines = 0
        versionLabel.textAlignment = .center

        tableFooterView = UIView()
        tableFooterView.addSubview(versionLabel)

        super.init(nibName: nil, bundle: nil)

        let tableViewDataSource = UITableViewDiffableDataSource<AboutSettingsSection, AboutSettingsEntry>(tableView: tableView) { [weak self] tableView, indexPath, itemIdentifier in
            
            guard let self,
                  let cell = tableView.dequeueReusableCell(withIdentifier: AboutMastodonTableViewCell.reuseIdentifier, for: indexPath) as? AboutMastodonTableViewCell else {
                assertionFailure("unexpected cell dequeued")
                return nil
            }

            let entry = self.sections[indexPath.section].entries[indexPath.row]
            cell.configure(with: entry)
            
            return cell
        }
        
        tableView.delegate = self
        tableView.dataSource = tableViewDataSource
        tableView.tableFooterView = tableFooterView

        self.tableViewDataSource = tableViewDataSource

        view.addSubview(tableView)
        view.backgroundColor = .systemGroupedBackground
        title = L10n.Scene.Settings.AboutMastodon.title

        setupConstraints()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let footerView = self.tableView.tableFooterView else {
            return
        }

        let width = self.tableView.bounds.size.width
        let size = footerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height))
        if footerView.frame.size.height != size.height {
            footerView.frame.size.height = size.height
            self.tableView.tableFooterView = footerView
        }
    }

    private func setupConstraints() {
        let constraints = [
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: tableView.safeAreaLayoutGuide.bottomAnchor),

            versionLabel.topAnchor.constraint(equalTo: tableFooterView.topAnchor, constant: 8),
            versionLabel.leadingAnchor.constraint(equalTo: tableFooterView.leadingAnchor),
            tableFooterView.trailingAnchor.constraint(equalTo: versionLabel.trailingAnchor),
            tableFooterView.bottomAnchor.constraint(equalTo: versionLabel.bottomAnchor, constant: 16),

        ]

        NSLayoutConstraint.activate(constraints)
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

