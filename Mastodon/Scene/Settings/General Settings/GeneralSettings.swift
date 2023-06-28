// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit

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
        case .appearance:
            return "Appearance"
        case .design:
            return "Design"
        case .links:
            return "Links"
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
                return "Light"
            case .dark:
                return "Dark"
            case .system:
                return "Use Device Appearance"
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
                return "Play Animated Avatars and Emoji"
            }
        }
    }

    enum OpenLinksIn: Hashable, CaseIterable {
        case mastodon
        case browser

        var title: String {
            switch self {
            case .mastodon:
                return "Open in Mastodon"
            case .browser:
                return "Open in Browser"
            }
        }
    }
}
