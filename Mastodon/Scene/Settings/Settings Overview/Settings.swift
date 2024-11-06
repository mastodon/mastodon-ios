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
    case logout(accountName: String)
    case toggleTestDonations
    case clearPreviousDonationCampaigns

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
                return L10n.Scene.Settings.Overview.manageDonations
            case .aboutMastodon:
                return L10n.Scene.Settings.Overview.aboutMastodon
            case .logout(let accountName):
                return L10n.Scene.Settings.Overview.logout(accountName)
            case .toggleTestDonations:
                return Mastodon.API.isTestingDonations ? "Donations use staging: ON" : "Donations use staging: OFF"
            case .clearPreviousDonationCampaigns:
                return "Clear Donation History"
        }
    }

    var secondaryTitle: String? {
        switch self {
            case .serverDetails(domain: let domain):
                return domain
            case .general, .notifications, .privacySafety, .makeDonation, .manageDonations, .aboutMastodon, .logout(_):
                return nil
            case .toggleTestDonations, .clearPreviousDonationCampaigns:
                return nil
        }
    }

    var accessoryType: UITableViewCell.AccessoryType {
        switch self {
            case .general, .notifications, .privacySafety, .serverDetails(_), .makeDonation, .manageDonations, .aboutMastodon, .logout(_):
                return .disclosureIndicator
            case .toggleTestDonations, .clearPreviousDonationCampaigns:
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
            case .logout(_):
                return nil
            case .toggleTestDonations, .clearPreviousDonationCampaigns:
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
            case .makeDonation, .manageDonations:
                return .systemPurple
            case .aboutMastodon:
                return .systemPurple
            case .logout(_):
                return nil
            case .toggleTestDonations, .clearPreviousDonationCampaigns:
                return nil
        }

    }

    var textColor: UIColor {
        switch self {
        case .general, .notifications, .privacySafety, .makeDonation, .manageDonations, .aboutMastodon, .serverDetails(_):
                return .label
            case .logout(_):
                return .red
            case .toggleTestDonations, .clearPreviousDonationCampaigns:
                return .systemIndigo
        }

    }
}
