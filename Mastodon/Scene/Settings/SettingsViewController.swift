//
//  SettingsViewController.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/7.
//

import os.log
import UIKit
import Combine
import ActiveLabel
import CoreData
import CoreDataStack
import AlamofireImage
import Kingfisher

// iTODO: when to ask permission to Use Notifications

class SettingsViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: SettingsViewModel! { willSet { precondition(!isViewLoaded) } }
    var disposeBag = Set<AnyCancellable>()
    
    var triggerMenu: UIMenu {
        let anyone = L10n.Scene.Settings.Section.Notifications.Trigger.anyone
        let follower = L10n.Scene.Settings.Section.Notifications.Trigger.follower
        let follow = L10n.Scene.Settings.Section.Notifications.Trigger.follow
        let noOne = L10n.Scene.Settings.Section.Notifications.Trigger.noone
        let menu = UIMenu(
            image: nil,
            identifier: nil,
            options: .displayInline,
            children: [
                UIAction(title: anyone, image: UIImage(systemName: "person.3"), attributes: []) { [weak self] action in
                    self?.updateTrigger(by: anyone)
                },
                UIAction(title: follower, image: UIImage(systemName: "person.crop.circle.badge.plus"), attributes: []) { [weak self] action in
                    self?.updateTrigger(by: follower)
                },
                UIAction(title: follow, image: UIImage(systemName: "person.crop.circle.badge.checkmark"), attributes: []) { [weak self] action in
                    self?.updateTrigger(by: follow)
                },
                UIAction(title: noOne, image: UIImage(systemName: "nosign"), attributes: []) { [weak self] action in
                    self?.updateTrigger(by: noOne)
                },
            ].reversed()
        )
        return menu
    }
    
    lazy var notifySectionHeader: UIView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 15, left: 4, bottom: 5, right: 4)
        view.axis = .horizontal
        view.alignment = .fill
        view.distribution = .equalSpacing
        view.spacing = 4
        
        let notifyLabel = UILabel()
        notifyLabel.translatesAutoresizingMaskIntoConstraints = false
        notifyLabel.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .semibold))
        notifyLabel.textColor = Asset.Colors.Label.primary.color
        notifyLabel.text = L10n.Scene.Settings.Section.Notifications.Trigger.title
        view.addArrangedSubview(notifyLabel)
        view.addArrangedSubview(whoButton)
        return view
    }()
    
    lazy var whoButton: UIButton = {
        let whoButton = UIButton(type: .roundedRect)
        whoButton.menu = triggerMenu
        whoButton.showsMenuAsPrimaryAction = true
        whoButton.setBackgroundColor(Asset.Colors.battleshipGrey.color, for: .normal)
        whoButton.setTitleColor(Asset.Colors.Label.primary.color, for: .normal)
        if let setting = self.viewModel.setting.value, let trigger = setting.triggerBy {
            whoButton.setTitle(trigger, for: .normal)
        }
        whoButton.titleLabel?.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .semibold))
        whoButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        whoButton.layer.cornerRadius = 10
        whoButton.clipsToBounds = true
        return whoButton
    }()
    
    lazy var tableView: UITableView = {
        // init with a frame to fix a conflict ('UIView-Encapsulated-Layout-Width' UIStackView:0x7f8c2b6c0590.width == 0)
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 320), style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        
        tableView.register(SettingsAppearanceTableViewCell.self, forCellReuseIdentifier: "SettingsAppearanceTableViewCell")
        tableView.register(SettingsToggleTableViewCell.self, forCellReuseIdentifier: "SettingsToggleTableViewCell")
        tableView.register(SettingsLinkTableViewCell.self, forCellReuseIdentifier: "SettingsLinkTableViewCell")
        return tableView
    }()
    
    lazy var footerView: UIView = {
        // init with a frame to fix a conflict ('UIView-Encapsulated-Layout-Height' UIStackView:0x7ffe41e47da0.height == 0)
        let view = UIStackView(frame: CGRect(x: 0, y: 0, width: 320, height: 320))
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.axis = .vertical
        view.alignment = .center
        
        let label = ActiveLabel(style: .default)
        label.textAlignment = .center
        label.configure(content: "Mastodon is open source software. You can contribute or report issues on GitHub at <a href=\"https://github.com/tootsuite/mastodon\">tootsuite/mastodon</a> (v3.3.0).")
        label.delegate = self
        
        view.addArrangedSubview(label)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        bindViewModel()
        
        viewModel.viewDidLoad.send()
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
    
    // MAKR: - Private methods
    private func bindViewModel() {
        let input = SettingsViewModel.Input()
        _ = viewModel.transform(input: input)
    }
    
    private func setupView() {
        view.backgroundColor = Asset.Colors.Background.systemGroupedBackground.color
        setupNavigation()
        setupTableView()
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem
            = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                              target: self,
                              action: #selector(doneButtonDidClick))
        navigationItem.title = L10n.Scene.Settings.title
        
        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithDefaultBackground()
        navigationItem.standardAppearance = barAppearance
        navigationItem.compactAppearance = barAppearance
        navigationItem.scrollEdgeAppearance = barAppearance
    }
    
    private func setupTableView() {
        viewModel.dataSource = UITableViewDiffableDataSource(tableView: tableView, cellProvider: { [weak self] (tableView, indexPath, item) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .apperance(let item):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsAppearanceTableViewCell") as? SettingsAppearanceTableViewCell else {
                    assertionFailure()
                    return nil
                }
                cell.update(with: item, delegate: self)
                return cell
            case .notification(let item):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsToggleTableViewCell") as? SettingsToggleTableViewCell else {
                    assertionFailure()
                    return nil
                }
                cell.update(with: item, delegate: self)
                return cell
            case .boringZone(let item), .spicyZone(let item):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsLinkTableViewCell") as? SettingsLinkTableViewCell else {
                    assertionFailure()
                    return nil
                }
                cell.update(with: item)
                return cell
            }
        })
        
        tableView.tableFooterView = footerView
    }
    
    func alertToSignout() {
        let alertController = UIAlertController(
            title: L10n.Common.Alerts.SignOut.title,
            message: L10n.Common.Alerts.SignOut.message,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
        let signOutAction = UIAlertAction(title: L10n.Common.Alerts.SignOut.confirm, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.signout()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)
        self.coordinator.present(
            scene: .alertController(alertController: alertController),
            from: self,
            transition: .alertController(animated: true, completion: nil)
        )
    }
    
    func signout() {
        guard let activeMastodonAuthenticationBox = context.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
        
        context.authenticationService.signOutMastodonUser(
            domain: activeMastodonAuthenticationBox.domain,
            userID: activeMastodonAuthenticationBox.userID
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                assertionFailure(error.localizedDescription)
            case .success(let isSignOut):
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: sign out %s", ((#file as NSString).lastPathComponent), #line, #function, isSignOut ? "success" : "fail")
                guard isSignOut else { return }
                self.coordinator.setup()
                self.coordinator.setupOnboardingIfNeeds(animated: true)
            }
        }
        .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
    // Mark: - Actions
    @objc func doneButtonDidClick() {
        dismiss(animated: true, completion: nil)
    }
}

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sections = viewModel.dataSource.snapshot().sectionIdentifiers
        guard section < sections.count else { return nil }
        let sectionData = sections[section]
        
        if section == 1 {
            let header = SettingsSectionHeader(
                frame: CGRect(x: 0, y: 0, width: 375, height: 66),
                customView: notifySectionHeader)
            header.update(title: sectionData.title)
            
            if let setting = self.viewModel.setting.value, let trigger = setting.triggerBy {
                whoButton.setTitle(trigger, for: .normal)
            } else {
                let anyone = L10n.Scene.Settings.Section.Notifications.Trigger.anyone
                whoButton.setTitle(anyone, for: .normal)
            }
            return header
        } else {
            let header = SettingsSectionHeader(frame: CGRect(x: 0, y: 0, width: 375, height: 66))
            header.update(title: sectionData.title)
            return header
        }
    }
    
    // remove the gap of table's footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    // remove the gap of table's footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = self.viewModel.dataSource.snapshot()
        let sectionIds = snapshot.sectionIdentifiers
        guard indexPath.section < sectionIds.count else { return }
        let sectionIdentifier = sectionIds[indexPath.section]
        let items = snapshot.itemIdentifiers(inSection: sectionIdentifier)
        guard indexPath.row < items.count else { return }
        let item = items[indexPath.item]
        
        switch item {
        case .boringZone:
            coordinator.present(
                scene: .safari(url: URL(string: "https://mastodon.online/terms")!),
                from: self,
                transition: .safariPresent(animated: true, completion: nil)
            )
        case .spicyZone(let link):
            // clear media cache
            if link.title == L10n.Scene.Settings.Section.Spicyzone.clear {
                // clean image cache for AlamofireImage
                let diskBytes = ImageDownloader.defaultURLCache().currentDiskUsage
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: diskBytes %d", ((#file as NSString).lastPathComponent), #line, #function, diskBytes)
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: clean image cache", ((#file as NSString).lastPathComponent), #line, #function)
                ImageDownloader.defaultURLCache().removeAllCachedResponses()
                let cleanedDiskBytes = ImageDownloader.defaultURLCache().currentDiskUsage
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: diskBytes %d", ((#file as NSString).lastPathComponent), #line, #function, cleanedDiskBytes)
                
                // clean Kingfisher Cache
                KingfisherManager.shared.cache.clearDiskCache()
            }
            // logout
            if link.title == L10n.Scene.Settings.Section.Spicyzone.signout {
                alertToSignout()
            }
        default:
            break
        }
    }
}

// Update setting into core data
extension SettingsViewController {
    func updateTrigger(by who: String) {
        guard let setting = self.viewModel.setting.value else { return }
        
        context.managedObjectContext.performChanges {
            setting.update(triggerBy: who)
        }
        .sink { (_) in
        }.store(in: &disposeBag)
    }
    
    func updateAlert(title: String?, isOn: Bool) {
        guard let title = title else { return }
        guard let settings = self.viewModel.setting.value else { return }
        guard let triggerBy = settings.triggerBy else { return }
        
        guard let alerts = settings.subscription?.first(where: { (s) -> Bool in
            return s.type == settings.triggerBy
        })?.alert else {
            return
        }
        var alertValues = [Bool?]()
        alertValues.append(alerts.favourite?.boolValue)
        alertValues.append(alerts.follow?.boolValue)
        alertValues.append(alerts.reblog?.boolValue)
        alertValues.append(alerts.mention?.boolValue)
        
        // need to update `alerts` to make update API with correct parameter
        switch title {
        case L10n.Scene.Settings.Section.Notifications.favorites:
            alertValues[0] = isOn
            alerts.favourite = NSNumber(booleanLiteral: isOn)
        case L10n.Scene.Settings.Section.Notifications.follows:
            alertValues[1] = isOn
            alerts.follow = NSNumber(booleanLiteral: isOn)
        case L10n.Scene.Settings.Section.Notifications.boosts:
            alertValues[2] = isOn
            alerts.reblog = NSNumber(booleanLiteral: isOn)
        case L10n.Scene.Settings.Section.Notifications.mentions:
            alertValues[3] = isOn
            alerts.mention = NSNumber(booleanLiteral: isOn)
        default: break
        }
        self.viewModel.updateSubscriptionSubject.send((triggerBy: triggerBy, values: alertValues))
    }
}

extension SettingsViewController: SettingsAppearanceTableViewCellDelegate {
    func settingsAppearanceCell(_ view: SettingsAppearanceTableViewCell, didSelect: SettingsItem.AppearanceMode) {
        guard let setting = self.viewModel.setting.value else { return }
        
        context.managedObjectContext.performChanges {
            setting.update(appearance: didSelect.rawValue)
        }
        .sink { (_) in
            // change light / dark mode
            var overrideUserInterfaceStyle: UIUserInterfaceStyle!
            switch didSelect {
            case .automatic:
                overrideUserInterfaceStyle = .unspecified
            case .light:
                overrideUserInterfaceStyle = .light
            case .dark:
                overrideUserInterfaceStyle = .dark
            }
            view.window?.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        }.store(in: &disposeBag)
    }
}

extension SettingsViewController: SettingsToggleCellDelegate {
    func settingsToggleCell(_ cell: SettingsToggleTableViewCell, didChangeStatus: Bool) {
        updateAlert(title: cell.data?.title, isOn: didChangeStatus)
    }
}

extension SettingsViewController: ActiveLabelDelegate {
    func activeLabel(_ activeLabel: ActiveLabel, didSelectActiveEntity entity: ActiveEntity) {
        coordinator.present(
            scene: .safari(url: URL(string: "https://github.com/tootsuite/mastodon")!),
            from: self,
            transition: .safariPresent(animated: true, completion: nil)
        )
    }
}

extension SettingsViewController {
    static func updateOverrideUserInterfaceStyle(window: UIWindow?) {
        guard let box = AppContext.shared.authenticationService.activeMastodonAuthenticationBox.value else {
            return
        }
            
        guard let setting: Setting? = {
            let domain = box.domain
            let request = Setting.sortedFetchRequest
            request.predicate = Setting.predicate(domain: domain)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try AppContext.shared.managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }() else { return }
        
        guard let didSelect = SettingsItem.AppearanceMode(rawValue: setting?.appearance ?? "") else {
            return
        }
        
        var overrideUserInterfaceStyle: UIUserInterfaceStyle!
        switch didSelect {
        case .automatic:
            overrideUserInterfaceStyle = .unspecified
        case .light:
            overrideUserInterfaceStyle = .light
        case .dark:
            overrideUserInterfaceStyle = .dark
        }
        window?.overrideUserInterfaceStyle = overrideUserInterfaceStyle
    }
}

#if canImport(SwiftUI) && DEBUG
import SwiftUI

struct SettingsViewController_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UIViewControllerPreview { () -> UIViewController in
                return SettingsViewController()
            }
            .previewLayout(.fixed(width: 390, height: 844))
        }
    }
    
}

#endif
