// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import UIKit
import MastodonLocalization
import MastodonSDK

struct SettingsSection: Hashable {
    let entries: [SettingsEntry]
}

enum SettingsEntry: Hashable {
    case general
    case notifications
    case privacySafety
    case serverDetails(domain: String)
    case aboutMastodon
    case makeDonation
    case manageDonations
    case loggedInAs(accountName: String)
    case manageBetaFeatures

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
            case .makeDonation:
                return L10n.Scene.Settings.Overview.supportMastodon
            case .manageDonations:
            return L10n.Scene.Settings.Donation.manage
            case .aboutMastodon:
                return L10n.Scene.Settings.Overview.aboutMastodon
            case .loggedInAs(let accountName):
                return L10nLookup.Scene.Settings.Overview.loggedInAs(accountName)
            case .manageBetaFeatures:
                return "Beta Features"
        }
    }

    var secondaryTitle: String? {
        switch self {
            case .serverDetails(domain: let domain):
                return domain
            case .loggedInAs:
                return L10nLookup.Scene.Settings.Overview.accountSwitcherTip
            case .general, .notifications, .privacySafety, .makeDonation, .manageDonations, .aboutMastodon:
                return nil
        case .manageBetaFeatures:
                return nil
        }
    }

    var accessoryType: UITableViewCell.AccessoryType {
        switch self {
        case .general, .notifications, .privacySafety, .serverDetails(_), .manageDonations, .aboutMastodon, .loggedInAs(_), .manageBetaFeatures:
                return .disclosureIndicator
            case .makeDonation:
                return .none
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
            case .makeDonation:
                return UIImage(systemName: "heart.fill")
            case .manageDonations:
                return UIImage(systemName: "gear")
            case .aboutMastodon:
                return UIImage(systemName: "info.circle.fill")
            case .loggedInAs(_):
                return nil
            case .manageBetaFeatures:
                return UIImage(systemName: "wrench.adjustable.fill")
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
            case .makeDonation, .manageDonations:
                return .systemPurple
            case .aboutMastodon:
                return .systemPurple
            case .loggedInAs(_):
                return nil
            case .manageBetaFeatures:
                return .systemOrange
        }

    }

    var textColor: UIColor {
        switch self {
        case .general, .notifications, .privacySafety, .makeDonation, .manageDonations, .aboutMastodon, .serverDetails(_):
                return .label
            case .loggedInAs(_):
                return .label
            case .manageBetaFeatures:
                return .systemIndigo
        }

    }
}
