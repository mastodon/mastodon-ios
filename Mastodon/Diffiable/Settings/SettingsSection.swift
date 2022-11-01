//
//  SettingsSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import UIKit
import CoreData
import CoreDataStack
import MastodonAsset
import MastodonCore
import MastodonLocalization

enum SettingsSection: Hashable {
    case appearance
    case appearancePreference
    case preference
    case notifications
    case boringZone
    case spicyZone
    
    var title: String {
        switch self {
        case .appearance:           return L10n.Scene.Settings.Section.LookAndFeel.title
        case .appearancePreference: return ""
        case .preference:           return ""
        case .notifications:        return L10n.Scene.Settings.Section.Notifications.title
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
            case .appearance(let record):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsAppearanceTableViewCell.self), for: indexPath) as! SettingsAppearanceTableViewCell
                managedObjectContext.performAndWait {
                    guard let setting = record.object(in: managedObjectContext) else { return }
                    cell.configure(setting: setting)
                }
                cell.delegate = settingsAppearanceTableViewCellDelegate
                return cell
            case .appearancePreference(let record, _):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsToggleTableViewCell.self), for: indexPath) as! SettingsToggleTableViewCell
                cell.delegate = settingsToggleCellDelegate
                managedObjectContext.performAndWait {
                    guard let setting = record.object(in: managedObjectContext) else { return }
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
            case .preference(let record, _):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsToggleTableViewCell.self), for: indexPath) as! SettingsToggleTableViewCell
                cell.delegate = settingsToggleCellDelegate
                managedObjectContext.performAndWait {
                    guard let setting = record.object(in: managedObjectContext) else { return }
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
            case .notification(let record, let switchMode):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsToggleTableViewCell.self), for: indexPath) as! SettingsToggleTableViewCell
                managedObjectContext.performAndWait {
                    guard let setting = record.object(in: managedObjectContext) else { return }
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
            case .boringZone(let item),
                 .spicyZone(let item):
                let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: SettingsLinkTableViewCell.self), for: indexPath) as! SettingsLinkTableViewCell
                cell.update(with: item)
                return cell
            }   // end switch
        }
    }
}

extension SettingsSection {

    public static func configureSettingToggle(
        cell: SettingsToggleTableViewCell,
        item: SettingsItem,
        setting: Setting
    ) {
        switch item {
        case .appearancePreference(_, let appearanceType):
            cell.textLabel?.text = appearanceType.title
            
            switch appearanceType {
            case .preferredTrueDarkMode:
                cell.switchButton.isOn = setting.preferredTrueBlackDarkMode
            }
            
        case .preference(_, let preferenceType):
            cell.textLabel?.text = preferenceType.title
            
            switch preferenceType {
            case .disableAvatarAnimation:
                cell.switchButton.isOn = setting.preferredStaticAvatar
            case .disableEmojiAnimation:
                cell.switchButton.isOn = setting.preferredStaticEmoji
            case .useDefaultBrowser:
                cell.switchButton.isOn = setting.preferredUsingDefaultBrowser
            }
            
        default:
            assertionFailure()
        }
    }

    public static func configureSettingToggle(
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
