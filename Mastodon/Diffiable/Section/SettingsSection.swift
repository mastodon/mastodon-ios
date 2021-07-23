//
//  SettingsSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import UIKit
import CoreData
import CoreDataStack

enum SettingsSection: Hashable {
    case appearance
    case notifications
    case preference
    case boringZone
    case spicyZone
    
    var title: String {
        switch self {
        case .appearance:           return L10n.Scene.Settings.Section.Appearance.title
        case .notifications:        return L10n.Scene.Settings.Section.Notifications.title
        case .preference:           return L10n.Scene.Settings.Section.Preference.title
        case .boringZone:           return L10n.Scene.Settings.Section.BoringZone.title
        case .spicyZone:            return L10n.Scene.Settings.Section.SpicyZone.title
        }
    }
}

extension SettingsSection {
    static func tableViewDiffableDataSource(
        for tableView: UITableView,
        managedObjectContext: NSManagedObjectContext,
        settingsAppearanceTableViewCellDelegate: SettingsAppearanceTableViewCellDelegate,
        settingsToggleCellDelegate: SettingsToggleCellDelegate
    ) -> UITableViewDiffableDataSource<SettingsSection, SettingsItem> {
        UITableViewDiffableDataSource(tableView: tableView) { [
            weak settingsAppearanceTableViewCellDelegate,
            weak settingsToggleCellDelegate
        ] tableView, indexPath, item -> UITableViewCell? in
            switch item {
            case .appearance(let objectID):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsAppearanceTableViewCell.self), for: indexPath) as! SettingsAppearanceTableViewCell
                managedObjectContext.performAndWait {
                    let setting = managedObjectContext.object(with: objectID) as! Setting
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
            case .notification(let objectID, let switchMode):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsToggleTableViewCell.self), for: indexPath) as! SettingsToggleTableViewCell
                managedObjectContext.performAndWait {
                    let setting = managedObjectContext.object(with: objectID) as! Setting
                    if let subscription = setting.activeSubscription {
                        SettingsSection.configureSettingToggle(cell: cell, switchMode: switchMode, subscription: subscription)
                    }
                    ManagedObjectObserver.observe(object: setting)
                        .sink(receiveCompletion: { _ in
                            // do nothing
                        }, receiveValue: { [weak cell] change in
                            guard let cell = cell else { return }
                            guard case .update(let object) = change.changeType,
                                  let setting = object as? Setting else { return }
                            guard let subscription = setting.activeSubscription else { return }
                            SettingsSection.configureSettingToggle(cell: cell, switchMode: switchMode, subscription: subscription)
                        })
                        .store(in: &cell.disposeBag)
                }
                cell.delegate = settingsToggleCellDelegate
                return cell
            case .preference(let objectID, _):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsToggleTableViewCell.self), for: indexPath) as! SettingsToggleTableViewCell
                cell.delegate = settingsToggleCellDelegate
                managedObjectContext.performAndWait {
                    let setting = managedObjectContext.object(with: objectID) as! Setting
                    SettingsSection.configureSettingToggle(cell: cell, item: item, setting: setting)

                    ManagedObjectObserver.observe(object: setting)
                        .receive(on: DispatchQueue.main)
                        .sink(receiveCompletion: { _ in
                            // do nothing
                        }, receiveValue: { [weak cell] change in
                            guard let cell = cell else { return }
                            guard case .update(let object) = change.changeType,
                                  let setting = object as? Setting else { return }
                            SettingsSection.configureSettingToggle(cell: cell, item: item, setting: setting)
                        })
                        .store(in: &cell.disposeBag)
                }
                return cell
            case .boringZone(let item),
                 .spicyZone(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsLinkTableViewCell.self), for: indexPath) as! SettingsLinkTableViewCell
                cell.update(with: item)
                return cell
            }
        }
    }
}

extension SettingsSection {

    static func configureSettingToggle(
        cell: SettingsToggleTableViewCell,
        item: SettingsItem,
        setting: Setting
    ) {
        guard case let .preference(_, preferenceType) = item else { return }

        cell.textLabel?.text = preferenceType.title

        switch preferenceType {
        case .darkMode:
            cell.switchButton.isOn = setting.preferredTrueBlackDarkMode
        case .disableAvatarAnimation:
            cell.switchButton.isOn = setting.preferredStaticAvatar
        case .disableEmojiAnimation:
            cell.switchButton.isOn = setting.preferredStaticEmoji
        case .useDefaultBrowser:
            cell.switchButton.isOn = setting.preferredUsingDefaultBrowser
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
