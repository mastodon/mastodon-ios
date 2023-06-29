// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

struct GeneralSettingsSection: Hashable {
    let type: GeneralSettingsSectionType
    let entries: [GeneralSetting]
}

enum GeneralSettingsSectionType: Hashable {
    case appearance
    case design
    case links

    var sectionTitle: String {
        switch self {
            //TODO: @zeitschlag Localization
        case .appearance:
            return L10n.Scene.Settings.General.Appearance.sectionTitle
        case .design:
            return L10n.Scene.Settings.General.Design.sectionTitle
        case .links:
            return L10n.Scene.Settings.General.Links.sectionTitle
        }
    }
}

enum GeneralSetting: Hashable {

    case appearance(Appearance)
    case design(Design)
    case openLinksIn(OpenLinksIn)

    enum Appearance: Int, CaseIterable {
        case light = 1
        case dark = 2
        case system = 0

        var title: String {
            switch self {
            case .light:
                return L10n.Scene.Settings.General.Appearance.light
            case .dark:
                return L10n.Scene.Settings.General.Appearance.dark
            case .system:
                return L10n.Scene.Settings.General.Appearance.system
            }
        }

        var interfaceStyle: UIUserInterfaceStyle {
            .init(rawValue: rawValue) ?? .unspecified
        }
    }

    enum Design: Hashable {
        case showAnimations

        var title: String {
            switch self {
            case .showAnimations:
                return L10n.Scene.Settings.General.Design.showAnimations
            }
        }
    }

    enum OpenLinksIn: Hashable, CaseIterable {
        case mastodon
        case browser

        var title: String {
            switch self {
            case .mastodon:
                return L10n.Scene.Settings.General.Links.openInMastodon
            case .browser:
                return L10n.Scene.Settings.General.Links.openInBrowser
            }
        }
    }
}
