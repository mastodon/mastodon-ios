//
//  SettingsViewModel.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/7.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import UIKit
import os.log

class SettingsViewModel {
    
    var disposeBag = Set<AnyCancellable>()

    let context: AppContext
    
    // input
    let setting: CurrentValueSubject<Setting, Never>
    var updateDisposeBag = Set<AnyCancellable>()
    var createDisposeBag = Set<AnyCancellable>()
    
    let viewDidLoad = PassthroughSubject<Void, Never>()
    
    // output
    var dataSource: UITableViewDiffableDataSource<SettingsSection, SettingsItem>!
    /// create a subscription when:
    /// - does not has one
    /// - does not find subscription for selected trigger when change trigger
    let createSubscriptionSubject = PassthroughSubject<(triggerBy: String, values: [Bool?]), Never>()
    let currentInstance = CurrentValueSubject<Mastodon.Entity.Instance?, Never>(nil)
    
    /// update a subscription when:
    /// - change switch for specified alerts
    let updateSubscriptionSubject = PassthroughSubject<(triggerBy: String, values: [Bool?]), Never>()
    
    lazy var privacyURL: URL? = {
        guard let box = AppContext.shared.authenticationService.activeMastodonAuthenticationBox.value else {
            return nil
        }
        
        return Mastodon.API.privacyURL(domain: box.domain)
    }()
    
    init(context: AppContext, setting: Setting) {
        self.context = context
        self.setting = CurrentValueSubject(setting)
        
        self.setting
            .sink(receiveValue: { [weak self] setting in
                guard let self = self else { return }
                self.processDataSource(setting)
            })
            .store(in: &disposeBag)

        context.authenticationService.activeMastodonAuthenticationBox
            .compactMap { $0?.domain }
            .map { context.apiService.instance(domain: $0) }
            .switchToLatest()
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .failure(let error):
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch instance fail: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    self.currentInstance.value = nil
                case .finished:
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: fetch instance success", ((#file as NSString).lastPathComponent), #line, #function)

                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                self.currentInstance.value = response.value
            }
            .store(in: &disposeBag)
    }
    
    deinit {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s:", ((#file as NSString).lastPathComponent), #line, #function)
    }
    
}

extension SettingsViewModel {
    
    // MARK: - Private methods
    private func processDataSource(_ setting: Setting) {
        guard let dataSource = self.dataSource else { return }
        var snapshot = NSDiffableDataSourceSnapshot<SettingsSection, SettingsItem>()

        // appearance
        let appearanceItems = [SettingsItem.appearance(settingObjectID: setting.objectID)]
        snapshot.appendSections([.appearance])
        snapshot.appendItems(appearanceItems, toSection: .appearance)

        let appearanceSettingItems = [
            SettingsItem.appearanceDarkMode(settingObjectID: setting.objectID),
            SettingsItem.appearanceDisableAvatarAnimation(settingObjectID: setting.objectID)
        ]
        snapshot.appendSections([.appearanceSettings])
        snapshot.appendItems(appearanceSettingItems, toSection: .appearanceSettings)
        
        let notificationItems = SettingsItem.NotificationSwitchMode.allCases.map { mode in
            SettingsItem.notification(settingObjectID: setting.objectID, switchMode: mode)
        }
        snapshot.appendSections([.notifications])
        snapshot.appendItems(notificationItems, toSection: .notifications)

        // boring zone
        let boringZoneSettingsItems: [SettingsItem] = {
            let links: [SettingsItem.Link] = [
                .termsOfService,
                .privacyPolicy
            ]
            let items = links.map { SettingsItem.boringZone(item: $0) }
            return items
        }()
        snapshot.appendSections([.boringZone])
        snapshot.appendItems(boringZoneSettingsItems, toSection: .boringZone)
        
        let spicyZoneSettingsItems: [SettingsItem] = {
            let links: [SettingsItem.Link] = [
                .clearMediaCache,
                .signOut
            ]
            let items = links.map { SettingsItem.spicyZone(item: $0) }
            return items
        }()
        snapshot.appendSections([.spicyZone])
        snapshot.appendItems(spicyZoneSettingsItems, toSection: .spicyZone)

        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
}

extension SettingsViewModel {
    func setupDiffableDataSource(
        for tableView: UITableView,
        settingsAppearanceTableViewCellDelegate: SettingsAppearanceTableViewCellDelegate,
        settingsToggleCellDelegate: SettingsToggleCellDelegate
    ) {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [
            weak self,
            weak settingsAppearanceTableViewCellDelegate,
            weak settingsToggleCellDelegate
        ] tableView, indexPath, item -> UITableViewCell? in
            guard let self = self else { return nil }
            switch item {
            case .appearance(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsAppearanceTableViewCell.self), for: indexPath) as! SettingsAppearanceTableViewCell
                self.context.managedObjectContext.performAndWait {
                    let setting = self.context.managedObjectContext.object(with: objectID) as! Setting
                    cell.update(with: setting.appearance)
                    ManagedObjectObserver.observe(object: setting)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { _ in
                            // do nothing
                        }, receiveValue: { [weak cell] change in
                            guard let cell = cell else { return }
                            guard case .update(let object) = change.changeType,
                                  let setting = object as? Setting else { return }
                            cell.update(with: setting.appearance)
                        })
                        .store(in: &cell.disposeBag)
                }
                cell.delegate = settingsAppearanceTableViewCellDelegate
                return cell
            case .appearanceDarkMode(let objectID),
                 .appearanceDisableAvatarAnimation(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsToggleTableViewCell.self), for: indexPath) as! SettingsToggleTableViewCell
                cell.delegate = settingsToggleCellDelegate
                self.context.managedObjectContext.performAndWait {
                    let setting = self.context.managedObjectContext.object(with: objectID) as! Setting
                    SettingsViewModel.configureSettingToggle(cell: cell, item: item, setting: setting)

                    ManagedObjectObserver.observe(object: setting)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { _ in
                            // do nothing
                        }, receiveValue: { [weak cell] change in
                            guard let cell = cell else { return }
                            guard case .update(let object) = change.changeType,
                                  let setting = object as? Setting else { return }
                            SettingsViewModel.configureSettingToggle(cell: cell, item: item, setting: setting)
                        })
                        .store(in: &cell.disposeBag)
                }
                return cell
            case .notification(let objectID, let switchMode):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsToggleTableViewCell.self), for: indexPath) as! SettingsToggleTableViewCell
                self.context.managedObjectContext.performAndWait {
                    let setting = self.context.managedObjectContext.object(with: objectID) as! Setting
                    if let subscription = setting.activeSubscription {
                        SettingsViewModel.configureSettingToggle(cell: cell, switchMode: switchMode, subscription: subscription)
                    }
                    ManagedObjectObserver.observe(object: setting)
                        .sink(receiveCompletion: { _ in
                            // do nothing
                        }, receiveValue: { [weak cell] change in
                            guard let cell = cell else { return }
                            guard case .update(let object) = change.changeType,
                                  let setting = object as? Setting else { return }
                            guard let subscription = setting.activeSubscription else { return }
                            SettingsViewModel.configureSettingToggle(cell: cell, switchMode: switchMode, subscription: subscription)
                        })
                        .store(in: &cell.disposeBag)
                }
                cell.delegate = settingsToggleCellDelegate
                return cell
            case .boringZone(let item), .spicyZone(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsLinkTableViewCell.self), for: indexPath) as! SettingsLinkTableViewCell
                cell.update(with: item)
                return cell
            }
        }
        
        processDataSource(self.setting.value)
    }
}

extension SettingsViewModel {

    static func configureSettingToggle(
        cell: SettingsToggleTableViewCell,
        item: SettingsItem,
        setting: Setting
    ) {
        switch item {
        case .appearanceDarkMode:
            cell.textLabel?.text = L10n.Scene.Settings.Section.AppearanceSettings.DarkMode.title
            cell.switchButton.isOn = setting.preferredTrueBlackDarkMode
        case .appearanceDisableAvatarAnimation:
            cell.textLabel?.text = L10n.Scene.Settings.Section.AppearanceSettings.AvatarAnimation.title
            cell.switchButton.isOn = setting.preferredStaticAvatar
        default:
            assertionFailure()
        }
    }
    
    static func configureSettingToggle(
        cell: SettingsToggleTableViewCell,
        switchMode: SettingsItem.NotificationSwitchMode,
        subscription: NotificationSubscription
    ) {
        cell.textLabel?.text = switchMode.title
        
        let enabled: Bool?
        switch switchMode {
        case .favorite:     enabled = subscription.alert.favourite
        case .follow:       enabled = subscription.alert.follow
        case .reblog:       enabled = subscription.alert.reblog
        case .mention:      enabled = subscription.alert.mention
        }
        cell.update(enabled: enabled)
    }
    
}
