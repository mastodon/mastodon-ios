//
//  SettingsSection.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//

import Foundation

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
