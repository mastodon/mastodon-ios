// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

struct GeneralSettingsSection: Hashable {
    let type: GeneralSettingsSectionType
    let entries: [GeneralSetting]
}

enum GeneralSettingsSectionType: Hashable {
    case appearance
    case askBefore
    case design
    case language
    case links

    var sectionTitle: String {
        switch self {
        case .appearance:
            return L10n.Scene.Settings.General.Appearance.sectionTitle
        case .askBefore:
            return L10n.Scene.Settings.General.AskBefore.sectionTitle
        case .design:
            return L10n.Scene.Settings.General.Design.sectionTitle
        case .language:
            return L10n.Scene.Settings.General.Language.sectionTitle
        case .links:
            return L10n.Scene.Settings.General.Links.sectionTitle
        }
    }
}

enum GeneralSetting: Hashable {

    case appearance(Appearance)
    case askBefore(AskBefore)
    case design(Design)
    case language(Language)
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
    
    enum AskBefore: Hashable {
        case postingWithoutAltText
        case unfollowingSomeone
        case boostingAPost
        case deletingAPost
        
        var title: String {
            switch self {
            case .postingWithoutAltText:
                return L10n.Scene.Settings.General.AskBefore.postingWithoutAltText
            case .unfollowingSomeone:
                return L10n.Scene.Settings.General.AskBefore.unfollowingSomeone
            case .boostingAPost:
                return L10n.Scene.Settings.General.AskBefore.boostingAPost
            case .deletingAPost:
                return L10n.Scene.Settings.General.AskBefore.deletingAPost

            }
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
    
    enum Language: Hashable {
        case defaultPostLanguage
        
        var title: String {
            switch self {
            case .defaultPostLanguage:
                return L10n.Scene.Settings.General.Language.defaultPostLanguage
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
