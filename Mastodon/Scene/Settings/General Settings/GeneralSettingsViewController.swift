// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

struct GeneralSettingsViewModel {
    var selectedAppearence: GeneralSetting.Appearance
    var playAnimations: Bool
    var selectedOpenLinks: GeneralSetting.OpenLinksIn
}

protocol GeneralSettingsViewControllerDelegate: AnyObject {

}

class GeneralSettingsViewController: UIViewController {

    weak var delegate: GeneralSettingsViewControllerDelegate?
    let tableView: UITableView

    var tableViewDataSource: GeneralSettingsDiffableTableViewDataSource?
    private(set) var viewModel: GeneralSettingsViewModel

    let sections: [GeneralSettingsSection]

    init() {
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

        //FIXME: Get Values from Setting
        viewModel = GeneralSettingsViewModel(selectedAppearence: .dark, playAnimations: true, selectedOpenLinks: .browser)

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
            UserDefaults.shared.customUserInterfaceStyle = appearanceOption.interfaceStyle
        case .design(_):

            break
        case .openLinksIn(let openLinksInOption):
            viewModel.selectedOpenLinks = openLinksInOption
        }

        //TODO: @zeitschlag Store in Settings????

        if let snapshot = tableViewDataSource?.snapshot() {
            tableViewDataSource?.applySnapshotUsingReloadData(snapshot)
        }

        tableView.deselectRow(at: indexPath, animated: true)
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

        //TODO: @zeitschlag Store in Settings????

        if let snapshot = tableViewDataSource?.snapshot() {
            tableViewDataSource?.applySnapshotUsingReloadData(snapshot)
        }

    }
}
