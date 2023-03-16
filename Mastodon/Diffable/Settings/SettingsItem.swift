//
//  SettingsItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import UIKit
import CoreData
import CoreDataStack
import MastodonAsset
import MastodonLocalization

enum SettingsItem {
    case appearance(record: ManagedObjectRecord<Setting>)
    case preference(settingRecord: ManagedObjectRecord<Setting>, preferenceType: PreferenceType)
    case notification(settingRecord: ManagedObjectRecord<Setting>, switchMode: NotificationSwitchMode)
    case boringZone(item: Link)
    case spicyZone(item: Link)
}

extension SettingsItem {
    
    enum AppearanceMode: String {
        case system
        case dark
        case light
    }

    enum NotificationSwitchMode: CaseIterable, Hashable {
        case favorite
        case follow
        case reblog
        case mention
        
        var title: String {
            switch self {
            case .favorite: return L10n.Scene.Settings.Section.Notifications.favorites
            case .follow:   return L10n.Scene.Settings.Section.Notifications.follows
            case .reblog:   return L10n.Scene.Settings.Section.Notifications.boosts
            case .mention:  return L10n.Scene.Settings.Section.Notifications.mentions
            }
        }
    }

    enum PreferenceType: CaseIterable {
        case disableAvatarAnimation
        case disableEmojiAnimation
        case useDefaultBrowser

        var title: String {
            switch self {
            case .disableAvatarAnimation:   return L10n.Scene.Settings.Section.Preference.disableAvatarAnimation
            case .disableEmojiAnimation:    return L10n.Scene.Settings.Section.Preference.disableEmojiAnimation
            case .useDefaultBrowser:        return L10n.Scene.Settings.Section.Preference.usingDefaultBrowser
            }
        }
    }
    
    enum Link: CaseIterable, Hashable {
        case accountSettings
        case github
        case termsOfService
        case privacyPolicy
        case clearMediaCache
        case signOut
        
        var title: String {
            switch self {
            case .accountSettings:   return L10n.Scene.Settings.Section.BoringZone.accountSettings
            case .github:            return "GitHub"
            case .termsOfService:    return L10n.Scene.Settings.Section.BoringZone.terms
            case .privacyPolicy:     return L10n.Scene.Settings.Section.BoringZone.privacy
            case .clearMediaCache:   return L10n.Scene.Settings.Section.SpicyZone.clear
            case .signOut:           return L10n.Scene.Settings.Section.SpicyZone.signout
            }
        }
        
        var textColor: UIColor? {
            switch self {
            case .accountSettings:   return nil         // tintColor
            case .github:            return nil
            case .termsOfService:    return nil
            case .privacyPolicy:     return nil
            case .clearMediaCache:   return .systemRed
            case .signOut:           return .systemRed
            }
        }
    }
    
}

extension SettingsItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .appearance(let record):
            hasher.combine(String(describing: SettingsItem.AppearanceMode.self))
            hasher.combine(record)
        case .notification(let settingObjectID, let switchMode):
            hasher.combine(String(describing: SettingsItem.notification.self))
            hasher.combine(settingObjectID)
            hasher.combine(switchMode)
        case .preference(let settingObjectID, let preferenceType):
            hasher.combine(String(describing: SettingsItem.preference.self))
            hasher.combine(settingObjectID)
            hasher.combine(preferenceType)
        case .boringZone(let link):
            hasher.combine(String(describing: SettingsItem.boringZone.self))
            hasher.combine(link)
        case .spicyZone(let link):
            hasher.combine(String(describing: SettingsItem.spicyZone.self))
            hasher.combine(link)
        }
    }
}
