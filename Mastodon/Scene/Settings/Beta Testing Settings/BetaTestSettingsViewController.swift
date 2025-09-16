// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonSDK

struct BetaTestSettingsViewModel {
    let useStagingForDonations: Bool
    let testUnreadMarkersForNotifications: Bool
    
    init() {
        useStagingForDonations = UserDefaults.standard.useStagingForDonations
        testUnreadMarkersForNotifications = UserDefaults.standard.testUnreadMarkersForNotifications
    }
    
    func byToggling(_ setting: BetaTestSetting) -> BetaTestSettingsViewModel {
        switch setting {
        case .useStagingForDonations:
            UserDefaults.standard.toggleUseStagingForDonations()
        case .testUnreadMarkersForNotifications:
            UserDefaults.standard.toggleTestUnreadMarkersForNotifications()
        case .clearPreviousDonationCampaigns:
            assertionFailure("this is an action, not a setting")
            break
        }
        return BetaTestSettingsViewModel()
    }
}

enum BetaTestSettingsSectionType: Hashable {
    case donations
    case features
    
    var sectionTitle: String {
        switch self {
        case .donations:
            return "Donations"
        case .features:
            return "Features"
        }
    }
}

enum BetaTestSetting: Hashable {
    case useStagingForDonations
    case clearPreviousDonationCampaigns
    case testUnreadMarkersForNotifications
  
    var labelText: String {
        switch self {
        case .useStagingForDonations:
            return "Donations use test endpoint"
        case .clearPreviousDonationCampaigns:
            return "Clear donation history"
        case .testUnreadMarkersForNotifications:
            return "Test unread markers for notifications"
        }
    }
}

fileprivate typealias BasicCell = UITableViewCell
fileprivate let basicCellReuseIdentifier = "basic_cell"

class BetaTestSettingsViewController: UIViewController {
    
    let tableView: UITableView
    
    var tableViewDataSource: BetaTestSettingsDiffableTableViewDataSource?
    
    private var viewModel: BetaTestSettingsViewModel {
        didSet {
            loadFromViewModel(animated: true)
        }
    }
    
    init() {
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(BasicCell.self, forCellReuseIdentifier: basicCellReuseIdentifier)
        tableView.register(ToggleTableViewCell.self, forCellReuseIdentifier: ToggleTableViewCell.reuseIdentifier)
        
        viewModel = BetaTestSettingsViewModel()
        
        super.init(nibName: nil, bundle: nil)
        
        tableView.delegate = self
        
        let tableViewDataSource = BetaTestSettingsDiffableTableViewDataSource(tableView: tableView, cellProvider: { [weak self] tableView, indexPath, itemIdentifier in
            guard let self else { return nil }
            switch itemIdentifier {
            case .useStagingForDonations:
                guard let selectionCell = tableView.dequeueReusableCell(withIdentifier: ToggleTableViewCell.reuseIdentifier, for: indexPath) as? ToggleTableViewCell else { assertionFailure("unexpected cell type"); return nil }
                selectionCell.label.text = itemIdentifier.labelText
                selectionCell.toggle.isOn = self.viewModel.useStagingForDonations
                selectionCell.toggle.removeTarget(self, action: nil, for: .valueChanged)
                selectionCell.toggle.addTarget(self, action: #selector(didToggleDonationsStaging), for: .valueChanged)
                return selectionCell
            case .clearPreviousDonationCampaigns:
                let cell = tableView.dequeueReusableCell(withIdentifier: basicCellReuseIdentifier, for: indexPath)
                cell.textLabel?.text = itemIdentifier.labelText
                cell.textLabel?.textColor = .red
                return cell
            case .testUnreadMarkersForNotifications:
                guard let selectionCell = tableView.dequeueReusableCell(withIdentifier: ToggleTableViewCell.reuseIdentifier, for: indexPath) as? ToggleTableViewCell else { assertionFailure("unexpected cell type"); return nil }
                selectionCell.label.text = itemIdentifier.labelText
                selectionCell.label.numberOfLines = 0
                selectionCell.toggle.isOn = self.viewModel.testUnreadMarkersForNotifications
                selectionCell.toggle.removeTarget(self, action: nil, for: .valueChanged)
                selectionCell.toggle.addTarget(self, action: #selector(didToggleTestUnreadMarkers), for: .valueChanged)
                return selectionCell
            }
        })
        
        tableView.dataSource = tableViewDataSource
        self.tableViewDataSource = tableViewDataSource
        
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
        tableView.pinTo(to: view)
        
        title = "Beta Test Settings"
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadFromViewModel(animated: false)
    }
    
    @objc func didToggleDonationsStaging(_ sender: UISwitch) {
        viewModel = viewModel.byToggling(.useStagingForDonations)
    }
    
    @objc func didToggleTestUnreadMarkers(_ sender: UISwitch) {
        viewModel = viewModel.byToggling(.testUnreadMarkersForNotifications)
    }
    
    func loadFromViewModel(animated: Bool = true) {
        var snapshot = NSDiffableDataSourceSnapshot<BetaTestSettingsSectionType, BetaTestSetting>()
        snapshot.appendSections([.features])
        snapshot.appendItems([.testUnreadMarkersForNotifications])
        snapshot.appendSections([.donations])
        snapshot.appendItems([.useStagingForDonations], toSection: .donations)
        if viewModel.useStagingForDonations {
            snapshot.appendItems([.useStagingForDonations, .clearPreviousDonationCampaigns], toSection: .donations)
        }
        tableViewDataSource?.apply(snapshot, animatingDifferences: animated)
    }
}

extension BetaTestSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let identifier = tableViewDataSource?.itemIdentifier(for: indexPath) else { return }
        switch identifier {
        case .useStagingForDonations:
            break
        case .clearPreviousDonationCampaigns:
            Mastodon.Entity.DonationCampaign.forgetPreviousCampaigns()
            DispatchQueue.main.async {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        case .testUnreadMarkersForNotifications:
            break
        }
    }
}
