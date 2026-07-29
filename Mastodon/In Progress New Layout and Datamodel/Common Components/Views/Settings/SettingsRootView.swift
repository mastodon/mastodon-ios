// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK
import MastodonCore
import MastodonLocalization
import MastodonAsset

struct SettingsNavigationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigator = MastodonNavigationRouter()
    
    var body: some View {
        @Bindable var navigator = navigator
        NavigationStack(path: $navigator.navigationPath) {
            if let domain = AuthenticationServiceProvider.shared.currentActiveUser.value?.domain {
                SettingsRootView(domain: domain)
                    .navigationTitle(L10n.Scene.Settings.Overview.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.Common.Controls.Actions.done) {
                                dismiss()
                            }
                        }
                    }
            } else {
                Text("No logged in user.")
            }
        }
    }
}

struct SettingsRootView: View {
    let domain: String
    
    var settingsGroups: [SettingsGroup] {
        let all: [SettingsGroup] = [ .basic, .server, .donations, .betaFeatures ].filter { group in
            switch group {
            case .basic, .server: return true
            case .donations: return Mastodon.Entity.DonationCampaign.isEligibleForDonationsSettingsSection(domain: domain)
            case .betaFeatures:
                return UserDefaults.isDebugOrTestflightOrSimulator
            }
        }
        return all
    }
    
    var body: some View {
        Form {
            ForEach(settingsGroups) { group in
                Section {
                    ForEach(group.rows(domain: domain)) { row in
                        settingsRow(row)
                    }
                }
            }
        }
    }
    
    @ViewBuilder func settingsRow(_ setting: SettingsRow) -> some View {
        HStack(alignment: .top) {
            setting.icon
                .foregroundStyle(setting.iconTint)
            
            VStack(alignment: .leading) {
                Text(setting.title)
                    .foregroundStyle(setting.textColor)
                
                if let secondaryTitle = setting.secondaryTitle {
                    Text(secondaryTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            if setting.isNavigation {
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity)
            }
        }
    }
}

enum SettingsGroup: String, Identifiable {
    case basic
    case server
    case donations
    case betaFeatures
    
    func rows(domain: String) -> [SettingsRow] {
        switch self {
        case .basic:
            [.general, .notifications, .privacySafety]
        case .server:
            [.serverDetails(domain: domain), .aboutMastodon]
        case .donations:
            [.makeDonation, .manageDonations]
        case .betaFeatures:
            [.manageBetaFeatures]
        }
    }
    
    var id: String { rawValue }
}

enum SettingsRow: Hashable, Identifiable {
    case general
    case notifications
    case privacySafety
    case serverDetails(domain: String)
    case aboutMastodon
    case makeDonation
    case manageDonations
    case manageBetaFeatures
    
    var id: Self { self }
    
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
        case .manageBetaFeatures:
            return "Beta Features"
        }
    }
    
    var secondaryTitle: String? {
        switch self {
        case .serverDetails(domain: let domain):
            return domain
        case .general, .notifications, .privacySafety, .makeDonation, .manageDonations, .aboutMastodon:
            return nil
        case .manageBetaFeatures:
            return nil
        }
    }
    
    var isNavigation: Bool {
        switch self {
        case .general, .notifications, .privacySafety, .serverDetails(_), .manageDonations, .aboutMastodon, .manageBetaFeatures:
            return true
        case .makeDonation:
            return false
        }
    }
    
    var icon: Image {
        switch self {
        case .general:
            return Image(systemName: "gear")
        case .notifications:
            return Image(systemName: "bell.badge")
        case .privacySafety:
            return Image(systemName: "lock.fill")
        case .serverDetails(_):
            return Image(systemName: "server.rack")
        case .makeDonation:
            return Image(systemName: "heart.fill")
        case .manageDonations:
            return Image(systemName: "gear")
        case .aboutMastodon:
            return Image(systemName: "info.circle.fill")
        case .manageBetaFeatures:
            return Image(systemName: "wrench.adjustable.fill")
        }
    }
    
    var iconTint: Color {
        switch self {
        case .general:
            return .gray
        case .notifications:
            return .red
        case .privacySafety:
            return .blue
        case .serverDetails(_):
            return .teal
        case .makeDonation, .manageDonations:
            return Asset.Colors.accent.swiftUIColor
        case .aboutMastodon:
            return Asset.Colors.accent.swiftUIColor
        case .manageBetaFeatures:
            return .orange
        }
        
    }
    
    var textColor: Color {
        switch self {
        case .general, .notifications, .privacySafety, .makeDonation, .manageDonations, .aboutMastodon, .serverDetails(_):
            return .primary
        case .manageBetaFeatures:
            return Asset.Colors.accent.swiftUIColor
        }
        
    }
}
