//
//  SettingsItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import UIKit
import CoreData

enum SettingsItem: Hashable {
    case appearance(settingObjectID: NSManagedObjectID)
    case notification(settingObjectID: NSManagedObjectID, switchMode: NotificationSwitchMode)
    case boringZone(item: Link)
    case spicyZone(item: Link)
}

extension SettingsItem {
    
    enum AppearanceMode: String {
        case automatic
        case light
        case dark
    }
    
    enum NotificationSwitchMode: CaseIterable {
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
    
    enum Link: CaseIterable {
        case termsOfService
        case privacyPolicy
        case clearMediaCache
        case signOut
        
        var title: String {
            switch self {
            case .termsOfService:    return L10n.Scene.Settings.Section.Boringzone.terms
            case .privacyPolicy:     return L10n.Scene.Settings.Section.Boringzone.privacy
            case .clearMediaCache:   return L10n.Scene.Settings.Section.Spicyzone.clear
            case .signOut:           return L10n.Scene.Settings.Section.Spicyzone.signout
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .termsOfService:    return Asset.Colors.brandBlue.color
            case .privacyPolicy:     return Asset.Colors.brandBlue.color
            case .clearMediaCache:   return .systemRed
            case .signOut:           return .systemRed
            }
        }
    }
    
}
