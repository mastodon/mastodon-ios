// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK
import CoreDataStack

struct GeneralSettingsViewModel {
    var selectedAppearence: GeneralSetting.Appearance
    var playAnimations: Bool
    var selectedOpenLinks: GeneralSetting.OpenLinksIn
}

protocol GeneralSettingsViewControllerDelegate: AnyObject {
    func save(_ viewController: UIViewController, setting: Setting, viewModel: GeneralSettingsViewModel)
}

class GeneralSettingsViewController: UIViewController {

    weak var delegate: GeneralSettingsViewControllerDelegate?
    let tableView: UITableView

    var tableViewDataSource: GeneralSettingsDiffableTableViewDataSource?

    private(set) var viewModel: GeneralSettingsViewModel
    let setting: Setting

    let sections: [GeneralSettingsSection]

    init(setting: Setting) {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(GeneralSettingSelectionCell.self, forCellReuseIdentifier: GeneralSettingSelectionCell.reuseIdentifier)
        tableView.register(GeneralSettingToggleCell.self, forCellReuseIdentifier: GeneralSettingToggleCell.reuseIdentifier)

        sections = [
            GeneralSettingsSection(type: .appearance, entries: [
                .appearance(.light),
                .appearance(.dark),
                .appearance(.system)
            ]),
            GeneralSettingsSection(type: .design, entries: [
                .design(.showAnimations)
            ]),
            GeneralSettingsSection(type: .links, entries: [
                .openLinksIn(.mastodon),
                .openLinksIn(.browser),
            ])
        ]

        let openLinksIn: GeneralSetting.OpenLinksIn
        if setting.preferredUsingDefaultBrowser {
            openLinksIn = .browser
        } else {
            openLinksIn = .mastodon
        }
        let playAnimations = (setting.preferredStaticAvatar == false && setting.preferredStaticEmoji == false)
        viewModel = GeneralSettingsViewModel(
            selectedAppearence: GeneralSetting.Appearance(rawValue: UserDefaults.shared.customUserInterfaceStyle.rawValue) ?? .system,
            playAnimations: playAnimations,
            selectedOpenLinks: openLinksIn
        )

        self.setting = setting

        super.init(nibName: nil, bundle: nil)

        tableView.delegate = self

        let tableViewDataSource = GeneralSettingsDiffableTableViewDataSource(tableView: tableView, cellProvider: { tableView, indexPath, itemIdentifier in
            let cell: UITableViewCell
            switch itemIdentifier {
            case .appearance(let setting):
                guard let selectionCell = tableView.dequeueReusableCell(withIdentifier: GeneralSettingSelectionCell.reuseIdentifier, for: indexPath) as? GeneralSettingSelectionCell else { fatalError("WTF? Wrong Cell!") }

                selectionCell.configure(with: .appearance(setting), viewModel: self.viewModel)
                cell = selectionCell
            case .design(let setting):
                guard let toggleCell = tableView.dequeueReusableCell(withIdentifier: GeneralSettingToggleCell.reuseIdentifier, for: indexPath) as? GeneralSettingToggleCell else { fatalError("WTF? Wrong Cell!") }

                toggleCell.configure(with: .design(setting), viewModel: self.viewModel)
                toggleCell.delegate = self

                cell = toggleCell
            case .openLinksIn(let setting):
                guard let selectionCell = tableView.dequeueReusableCell(withIdentifier: GeneralSettingSelectionCell.reuseIdentifier, for: indexPath) as? GeneralSettingSelectionCell else { fatalError("WTF? Wrong Cell!") }

                selectionCell.configure(with: .openLinksIn(setting), viewModel: self.viewModel)

                cell = selectionCell
            }

            return cell
        })

        self.tableViewDataSource = tableViewDataSource

        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        tableView.pinTo(to: view)

        title = "General"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        var snapshot = NSDiffableDataSourceSnapshot<GeneralSettingsSection, GeneralSetting>()

        for section in sections {
            snapshot.appendSections([section])
            snapshot.appendItems(section.entries)
        }

        tableViewDataSource?.apply(snapshot, animatingDifferences: false)
    }
}

extension GeneralSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        // switch section

        let section = sections[indexPath.section].entries[indexPath.row]

        switch section {
        case .appearance(let appearanceOption):
            viewModel.selectedAppearence = appearanceOption
        case .design(_):

            break
        case .openLinksIn(let openLinksInOption):
            viewModel.selectedOpenLinks = openLinksInOption
        }

        if let snapshot = tableViewDataSource?.snapshot() {
            tableViewDataSource?.applySnapshotUsingReloadData(snapshot)
        }

        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.save(self, setting: setting, viewModel: viewModel)
    }
}

extension GeneralSettingsViewController: GeneralSettingToggleCellDelegate {
    func toggle(_ cell: GeneralSettingToggleCell, setting: GeneralSetting, isOn: Bool) {
        switch setting {
        case .appearance(_), .openLinksIn(_):
            assertionFailure("No toggle")
        case .design(let designSetting):
            switch designSetting {
            case .showAnimations:
                viewModel.playAnimations = isOn
            }
        }

        if let snapshot = tableViewDataSource?.snapshot() {
            tableViewDataSource?.applySnapshotUsingReloadData(snapshot)
        }
        delegate?.save(self, setting: self.setting, viewModel: viewModel)
    }
}
