// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization

struct SettingsSection: Hashable {
    let entries: [SettingsEntry]
}

enum SettingsEntry: Hashable {
    case general
    case notifications
    case privacySafety
    case serverDetails(domain: String)
    case aboutMastodon
    case logout(accountName: String)

    var title: String {
        switch self {
            case .general:
                return L10n.Scene.Settings.Overview.general
            case .notifications:
                return L10n.Scene.Settings.Overview.notifications
            case .privacySafety:
                return L10n.Scene.Settings.Overview.privacySafety
            case .serverDetails(_):
                return L10n.Scene.Settings.Overview.serverDetails
            case .aboutMastodon:
                return L10n.Scene.Settings.Overview.aboutMastodon
            case .logout(let accountName):
                return L10n.Scene.Settings.Overview.logout(accountName)
        }
    }

    var secondaryTitle: String? {
        switch self {
            case .serverDetails(domain: let domain):
                return domain
            case .general, .notifications, .privacySafety, .aboutMastodon, .logout(_):
                return nil
        }
    }

    var accessoryType: UITableViewCell.AccessoryType {
        switch self {
            case .general, .notifications, .privacySafety, .serverDetails(_), .aboutMastodon, .logout(_):
                return .disclosureIndicator
        }
    }

    var icon: UIImage? {
        switch self {
            case .general:
                return UIImage(systemName: "gear")
            case .notifications:
                return UIImage(systemName: "bell.badge")
            case .privacySafety:
                return UIImage(systemName: "lock.fill")
            case .serverDetails(_):
                return UIImage(systemName: "server.rack")
            case .aboutMastodon:
                return UIImage(systemName: "info.circle.fill")
            case .logout(_):
                return nil
        }
    }

    var iconBackgroundColor: UIColor? {
        switch self {
            case .general:
                return .systemGray
            case .notifications:
                return .systemRed
            case .privacySafety:
                return .systemBlue
            case .serverDetails(_):
                return .systemTeal
            case .aboutMastodon:
                return .systemPurple
            case .logout(_):
                return nil
        }

    }

    var textColor: UIColor {
        switch self {
            case .general, .notifications, .privacySafety, .aboutMastodon, .serverDetails(_):
                return .label
            case .logout(_):
                return .red
        }

    }
}
