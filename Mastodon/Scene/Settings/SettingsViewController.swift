//
//  SettingsViewController.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/7.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import AuthenticationServices
import MetaTextKit
import MastodonSDK
import MastodonMeta
import MastodonAsset
import MastodonCore
import MastodonUI
import MastodonLocalization

class SettingsViewController: UIViewController, NeedsDependency {
    
    weak var context: AppContext! { willSet { precondition(!isViewLoaded) } }
    weak var coordinator: SceneCoordinator! { willSet { precondition(!isViewLoaded) } }
    
    var viewModel: SettingsViewModel! { willSet { precondition(!isViewLoaded) } }
    var disposeBag = Set<AnyCancellable>()
    var notificationPolicySubscription: AnyCancellable?
    
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
                    self?.updateTrigger(policy: .all)
                },
                UIAction(title: follower, image: UIImage(systemName: "person.crop.circle.badge.plus"), attributes: []) { [weak self] action in
                    self?.updateTrigger(policy: .follower)
                },
                UIAction(title: follow, image: UIImage(systemName: "person.crop.circle.badge.checkmark"), attributes: []) { [weak self] action in
                    self?.updateTrigger(policy: .followed)
                },
                UIAction(title: noOne, image: UIImage(systemName: "nosign"), attributes: []) { [weak self] action in
                    self?.updateTrigger(policy: .none)
                },
            ]
        )
        return menu
    }
    
    private let notifySectionHeaderStackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isLayoutMarginsRelativeArrangement = true
        view.axis = .horizontal
        view.spacing = 4
        return view
    }()
    
    let notifyLabel = UILabel()
    private(set) lazy var notifySectionHeader: UIView = {
        let view = notifySectionHeaderStackView
        
        notifyLabel.translatesAutoresizingMaskIntoConstraints = false
        notifyLabel.adjustsFontForContentSizeCategory = true
        notifyLabel.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .semibold))
        notifyLabel.textColor = Asset.Colors.Label.primary.color
        notifyLabel.text = L10n.Scene.Settings.Section.Notifications.Trigger.title
        notifyLabel.adjustsFontSizeToFitWidth = true
        notifyLabel.minimumScaleFactor = 0.5
        
        view.addArrangedSubview(notifyLabel)
        view.addArrangedSubview(whoButton)
        whoButton.setContentHuggingPriority(.defaultHigh + 1, for: .horizontal)
        whoButton.setContentHuggingPriority(.defaultHigh + 1, for: .vertical)
        
        return view
    }()
    
    private(set) lazy var whoButton: UIButton = {
        let whoButton = UIButton(type: .roundedRect)
        whoButton.menu = triggerMenu
        whoButton.showsMenuAsPrimaryAction = true
        whoButton.setBackgroundColor(Asset.Colors.battleshipGrey.color, for: .normal)
        whoButton.setTitleColor(Asset.Colors.Label.primary.color, for: .normal)
        whoButton.titleLabel?.adjustsFontForContentSizeCategory = true
        whoButton.titleLabel?.font = UIFontMetrics(forTextStyle: .title3).scaledFont(for: UIFont.systemFont(ofSize: 20, weight: .semibold))
        whoButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        whoButton.layer.cornerRadius = 10
        whoButton.clipsToBounds = true
        whoButton.titleLabel?.adjustsFontSizeToFitWidth = true
        whoButton.titleLabel?.minimumScaleFactor = 0.5
        return whoButton
    }()
    
    private(set) lazy var tableView: UITableView = {
        // init with a frame to fix a conflict ('UIView-Encapsulated-Layout-Width' UIStackView:0x7f8c2b6c0590.width == 0)
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: 320, height: 320), style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .clear
        tableView.separatorColor = ThemeService.shared.currentTheme.value.separator
        
        tableView.register(SettingsAppearanceTableViewCell.self, forCellReuseIdentifier: String(describing: SettingsAppearanceTableViewCell.self))
        tableView.register(SettingsToggleTableViewCell.self, forCellReuseIdentifier: String(describing: SettingsToggleTableViewCell.self))
        tableView.register(SettingsLinkTableViewCell.self, forCellReuseIdentifier: String(describing: SettingsLinkTableViewCell.self))
        return tableView
    }()

    let tableFooterLabel = MetaLabel(style: .settingTableFooter)
    lazy var tableFooterView: UIView = {
        // init with a frame to fix a conflict ('UIView-Encapsulated-Layout-Height' UIStackView:0x7ffe41e47da0.height == 0)
        let view = UIStackView(frame: CGRect(x: 0, y: 0, width: 320, height: 320))
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        view.axis = .vertical
        view.alignment = .center

        // tableFooterLabel.linkDelegate = self
        view.addArrangedSubview(tableFooterLabel)
        return view
    }()
    
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SettingsViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        bindViewModel()
        
        viewModel.viewDidLoad.send()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // make large title not collapsed
        navigationController?.navigationBar.sizeToFit()
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        updateSectionHeaderStackViewLayout()
    }
    
    
    // MAKR: - Private methods
    private func updateSectionHeaderStackViewLayout() {
        // accessibility
        if traitCollection.preferredContentSizeCategory < .accessibilityMedium {
            notifySectionHeaderStackView.axis = .horizontal
            notifyLabel.numberOfLines = 1
        } else {
            notifySectionHeaderStackView.axis = .vertical
            notifyLabel.numberOfLines = 0
        }
    }
    
    private func bindViewModel() {
        self.whoButton.setTitle(viewModel.setting.value.activeSubscription?.policy.title, for: .normal)
        viewModel.setting
            .sink { [weak self] setting in
                guard let self = self else { return }
                self.notificationPolicySubscription = ManagedObjectObserver.observe(object: setting)
                    .sink { _ in
                        // do nothing
                    } receiveValue: { [weak self] change in
                        guard let self = self else { return }
                        guard case let .update(object) = change.changeType,
                              let setting = object as? Setting else { return }
                        if let activeSubscription = setting.activeSubscription {
                            self.whoButton.setTitle(activeSubscription.policy.title, for: .normal)
                        } else {
                            // assertionFailure()
                        }
                    }
            }
            .store(in: &disposeBag)

        let footer = "Mastodon for iOS v\(UIApplication.appVersion()) (\(UIApplication.appBuild()))"
        let metaContent = PlaintextMetaContent(string: footer)
        tableFooterLabel.configure(content: metaContent)
    }
    
    private func setupView() {
        setupBackgroundColor(theme: ThemeService.shared.currentTheme.value)
        ThemeService.shared.currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                guard let self = self else { return }
                self.setupBackgroundColor(theme: theme)
            }
            .store(in: &disposeBag)

        setupNavigation()
        view.addSubview(tableView)
        tableView.pinToParent()
        setupTableView()
        
        updateSectionHeaderStackViewLayout()
    }

    private func setupBackgroundColor(theme: Theme) {
        view.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            switch traitCollection.userInterfaceLevel {
            case .elevated where traitCollection.userInterfaceStyle == .dark:
                return theme.systemElevatedBackgroundColor
            default:
                return theme.secondarySystemBackgroundColor
            }
        })

        tableView.separatorColor = theme.separator
    }
    
    private func setupNavigation() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem
            = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done,
                              target: self,
                              action: #selector(doneButtonDidClick))
        navigationItem.title = L10n.Scene.Settings.title
    }
    
    private func setupTableView() {
        viewModel.setupDiffableDataSource(
            for: tableView,
            settingsAppearanceTableViewCellDelegate: self,
            settingsToggleCellDelegate: self
        )
        tableView.tableFooterView = tableFooterView
    }
    
    func alertToSignOut() {
        let alertController = UIAlertController(
            title: L10n.Common.Alerts.SignOut.title,
            message: L10n.Common.Alerts.SignOut.message,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: L10n.Common.Controls.Actions.cancel, style: .cancel, handler: nil)
        let signOutAction = UIAlertAction(title: L10n.Common.Alerts.SignOut.confirm, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.signOut()
        }
        alertController.addAction(cancelAction)
        alertController.addAction(signOutAction)
        _ = self.coordinator.present(
            scene: .alertController(alertController: alertController),
            from: self,
            transition: .alertController(animated: true, completion: nil)
        )
    }
    
    func signOut() {
        // clear badge before sign-out
        context.notificationService.clearNotificationCountForActiveUser()
        
        Task { @MainActor in
            try await context.authenticationService.signOutMastodonUser(
                authenticationBox: viewModel.authContext.mastodonAuthenticationBox
            )
            self.coordinator.setup()
        }
    }
    
}

// Mark: - Actions
extension SettingsViewController {
    @objc private func doneButtonDidClick() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sections = viewModel.dataSource.snapshot().sectionIdentifiers
        guard section < sections.count else { return nil }
        
        let sectionIdentifier = sections[section]
        
        let header: SettingsSectionHeader
        switch sectionIdentifier {
        case .preference:
            return UIView()
        case .notifications:
            header = SettingsSectionHeader(
                frame: CGRect(x: 0, y: 0, width: 375, height: 66),
                customView: notifySectionHeader)
            header.update(title: sectionIdentifier.title)
        default:
            header = SettingsSectionHeader(frame: CGRect(x: 0, y: 0, width: 375, height: 66))
            header.update(title: sectionIdentifier.title)
        }
        header.preservesSuperviewLayoutMargins = true

        return header
    }

    // remove the gap of table's footer
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    // remove the gap of table's footer
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let dataSource = viewModel.dataSource else { return }
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        switch item {
        case .appearance:
            // do nothing
            break
        case .notification:
            // do nothing
            break
        case .preference:
            // do nothing
            break
        case .boringZone(let link), .spicyZone(let link):
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
            switch link {
            case .accountSettings:
                let domain = viewModel.authContext.mastodonAuthenticationBox.domain
                guard let url = URL(string: "https://\(domain)/auth/edit") else { return }
                viewModel.openAuthenticationPage(authenticateURL: url, presentationContextProvider: self)
            case .github:
                guard let url = URL(string: "https://github.com/mastodon/mastodon-ios") else { break }
                _ = coordinator.present(
                    scene: .safari(url: url),
                    from: self,
                    transition: .safariPresent(animated: true, completion: nil)
                )
            case .termsOfService, .privacyPolicy:
                // same URL
                guard let url = viewModel.privacyURL else { break }
                _ = coordinator.present(
                    scene: .safari(url: url),
                    from: self,
                    transition: .safariPresent(animated: true, completion: nil)
                )
            case .clearMediaCache:
                context.purgeCache()
                    .receive(on: RunLoop.main)
                    .sink { [weak self] byteCount in
                        guard let self = self else { return }
                        let byteCountFormatted = AppContext.byteCountFormatter.string(fromByteCount: Int64(byteCount))
                        let alertController = UIAlertController(
                            title: L10n.Common.Alerts.CleanCache.title,
                            message: L10n.Common.Alerts.CleanCache.message(byteCountFormatted),
                            preferredStyle: .alert
                        )
                        let okAction = UIAlertAction(title: L10n.Common.Controls.Actions.ok, style: .default, handler: nil)
                        alertController.addAction(okAction)
                        _ = self.coordinator.present(scene: .alertController(alertController: alertController), from: nil, transition: .alertController(animated: true, completion: nil))
                    }
                    .store(in: &disposeBag)
            case .signOut:
                feedbackGenerator.impactOccurred()
                alertToSignOut()
            }
        }
    }
}

// Update setting into core data
extension SettingsViewController {
    func updateTrigger(policy: Mastodon.API.Subscriptions.Policy) {
        let objectID = self.viewModel.setting.value.objectID
        let managedObjectContext = context.backgroundManagedObjectContext
        
        managedObjectContext.performChanges {
            let setting = managedObjectContext.object(with: objectID) as! Setting
            let (subscription, _) = APIService.CoreData.createOrFetchSubscription(
                into: managedObjectContext,
                setting: setting,
                policy: policy
            )
            let now = Date()
            subscription.update(activedAt: now)
            setting.didUpdate(at: now)
        }
        .sink { _ in
            // do nothing
        } receiveValue: { _ in
            // do nothing
        }
        .store(in: &disposeBag)
    }
}

// MARK: - SettingsAppearanceTableViewCellDelegate
extension SettingsViewController: SettingsAppearanceTableViewCellDelegate {
    func settingsAppearanceTableViewCell(
        _ cell: SettingsAppearanceTableViewCell,
        didSelectAppearanceMode appearanceMode: SettingsItem.AppearanceMode
    ) {
        guard let dataSource = viewModel.dataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let item = dataSource.itemIdentifier(for: indexPath)
        guard case .appearance = item else { return }
        
        Task { @MainActor in
            switch appearanceMode {
            case .system:
                UserDefaults.shared.customUserInterfaceStyle = .unspecified
            case .dark:
                UserDefaults.shared.customUserInterfaceStyle = .dark
            case .light:
                UserDefaults.shared.customUserInterfaceStyle = .light
            }
            
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
            feedbackGenerator.impactOccurred()
        }   // end Task
    }

}

extension SettingsViewController: SettingsToggleCellDelegate {
    func settingsToggleCell(_ cell: SettingsToggleTableViewCell, switchValueDidChange switch: UISwitch) {
        guard let dataSource = viewModel.dataSource else { return }
        guard let indexPath = tableView.indexPath(for: cell) else { return }

        let isOn = `switch`.isOn
        let item = dataSource.itemIdentifier(for: indexPath)

        switch item {
        case .notification(let record, let switchMode):
            let managedObjectContext = context.backgroundManagedObjectContext
            managedObjectContext.performChanges {
                guard let setting = record.object(in: managedObjectContext) else { return }
                guard let subscription = setting.activeSubscription else { return }
                let alert = subscription.alert
                switch switchMode {
                case .favorite:     alert.update(favourite: isOn)
                case .follow:       alert.update(follow: isOn)
                case .reblog:       alert.update(reblog: isOn)
                case .mention:      alert.update(mention: isOn)
                }
                // trigger setting update
                alert.subscription.setting?.didUpdate(at: Date())
            }
            .sink { _ in
                // do nothing
            }
            .store(in: &disposeBag)
        case .preference(let record, let preferenceType):
            let managedObjectContext = context.backgroundManagedObjectContext
            managedObjectContext.performChanges {
                guard let setting = record.object(in: managedObjectContext) else { return }
                switch preferenceType {
                case .disableAvatarAnimation:
                    setting.update(preferredStaticAvatar: isOn)
                case .disableEmojiAnimation:
                    setting.update(preferredStaticEmoji: isOn)
                case .useDefaultBrowser:
                    setting.update(preferredUsingDefaultBrowser: isOn)
                }
            }
            .sink { result in
                switch result {
                case .success:
                    switch preferenceType {
                    case .disableAvatarAnimation:
                        UserDefaults.shared.preferredStaticAvatar = isOn
                    case .disableEmojiAnimation:
                        UserDefaults.shared.preferredStaticEmoji = isOn
                    case .useDefaultBrowser:
                        UserDefaults.shared.preferredUsingDefaultBrowser = isOn
                    }
                case .failure(let error):
                    assertionFailure(error.localizedDescription)
                    break
                }
            }
            .store(in: &disposeBag)
        default:
            assertionFailure()
            break
        }
    }
}

// MARK: - MetaLabelDelegate
extension SettingsViewController: MetaLabelDelegate {
    func metaLabel(_ metaLabel: MetaLabel, didSelectMeta meta: Meta) {
        switch meta {
        case .url(_, _, let url, _):
            guard let url = URL(string: url) else { return }
            _ = coordinator.present(scene: .safari(url: url), from: self, transition: .safariPresent(animated: true, completion: nil))
        default:
            assertionFailure()
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension SettingsViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SettingsViewController: UIAdaptivePresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .pageSheet
    }
}

extension SettingsViewController {
    
    var closeKeyCommand: UIKeyCommand {
        UIKeyCommand(
            title: L10n.Scene.Settings.Keyboard.closeSettingsWindow,
            image: nil,
            action: #selector(SettingsViewController.closeSettingsWindowKeyCommandHandler(_:)),
            input: "w",
            modifierFlags: .command,
            propertyList: nil,
            alternates: [],
            discoverabilityTitle: nil,
            attributes: [],
            state: .off
        )
    }
    
    override var keyCommands: [UIKeyCommand]? {
        return [closeKeyCommand]
    }
    
    @objc private func closeSettingsWindowKeyCommandHandler(_ sender: UIKeyCommand) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s", ((#file as NSString).lastPathComponent), #line, #function)
        dismiss(animated: true, completion: nil)
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
