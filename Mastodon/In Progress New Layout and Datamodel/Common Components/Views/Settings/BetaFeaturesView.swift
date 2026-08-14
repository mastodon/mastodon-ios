// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

@MainActor
@Observable class BetaTestSettingsViewModel {
    var useStagingForDonations = false
//    var testUnreadMarkersForNotifications = false
    var showRateLimitTracker = false
    var showCollections = false
    var hasDonationHistory = false
    
    var sections: [BetaTestSettingSection] {
        [
            .init(type: .features, settings: [
                .showRateLimitTracker,
                .showCollectionsInFeatureTab]),
            .init(type: .donations, settings: [
                .useStagingForDonations,
                useStagingForDonations ? .clearPreviousDonationCampaigns : nil
            ].compactMap { $0 })
        ]
    }
    
    init() {
        load()
    }
    
    private func load() {
        useStagingForDonations = UserDefaults.standard.useStagingForDonations
//        testUnreadMarkersForNotifications = UserDefaults.standard.testUnreadMarkersForNotifications
        showRateLimitTracker = UserDefaults.standard.showRateLimitTracker
        showCollections = UserDefaults.standard.showCollections
        hasDonationHistory = Mastodon.Entity.DonationCampaign.hasHistory()
    }
    
    func clearDonationHistory() {
        Mastodon.Entity.DonationCampaign.forgetPreviousCampaigns()
        load()
    }
    
    private func toggle(_ setting: BetaTestSetting) {
        defer { load() }
        
        switch setting {
        case .useStagingForDonations:
            UserDefaults.standard.toggleUseStagingForDonations()
            //        case .testUnreadMarkersForNotifications:
            //            UserDefaults.standard.toggleTestUnreadMarkersForNotifications()
        case .showRateLimitTracker:
            UserDefaults.standard.toggleShowRateLimitTracker()
        case .clearPreviousDonationCampaigns:
            assertionFailure("this is an action, not a setting")
            break
        case .showCollectionsInFeatureTab:
            UserDefaults.standard.toggleShowCollections()
        }
    }
    
    func binding(_ setting: BetaTestSetting) -> Binding<Bool> {
        func currentValue(_ setting: BetaTestSetting) -> Bool {
            switch setting {
            case .useStagingForDonations: useStagingForDonations
            case .showRateLimitTracker: showRateLimitTracker
            case .showCollectionsInFeatureTab: showCollections
            case .clearPreviousDonationCampaigns: false
            }
        }
        return Binding<Bool>(
            get: { currentValue(setting) },
            set: { newValue in
                guard newValue != currentValue(setting) else { return }
                self.toggle(setting)
            })
    }
}

struct BetaTestSettingSection {
    let type: BetaTestSettingsSectionType
    let settings: [BetaTestSetting]
}

enum BetaTestSettingsSectionType: Hashable {
    case donations
    case features
    
    var sectionTitle: String {
        switch self {
        case .donations:
            return "Donations"
        case .features:
            return "Features"
        }
    }
}

enum BetaTestSetting: Hashable {
    case useStagingForDonations
    case clearPreviousDonationCampaigns
    //case testUnreadMarkersForNotifications
    case showRateLimitTracker
    case showCollectionsInFeatureTab
    
    var labelText: String {
        switch self {
        case .useStagingForDonations:
            return "Donations use test endpoint"
        case .clearPreviousDonationCampaigns:
            return "Clear donation history"
            //        case .testUnreadMarkersForNotifications:
            //            return "Test unread markers for notifications"
        case .showRateLimitTracker:
            return "Show API rate limit tracker"
        case .showCollectionsInFeatureTab:
            return "Show Collections"
        }
    }
}

struct BetaFeaturesView: View {
    @State var viewModel = BetaTestSettingsViewModel()
    
    var body: some View {
        Form {
            ForEach(viewModel.sections, id: \.self.type) { section in
                Section(section.type.sectionTitle) {
                    ForEach(section.settings, id: \.self) { setting in
                        row(setting)
                    }
                }
            }
        }
    }
    
    @ViewBuilder func row(_ setting: BetaTestSetting) -> some View {
        switch setting {
        case .showCollectionsInFeatureTab, .showRateLimitTracker, .useStagingForDonations:
            ToggleRow(label: setting.labelText, isOn: viewModel.binding(setting))
        case .clearPreviousDonationCampaigns:
            Button(role: .destructive) {
                viewModel.clearDonationHistory()
            } label: {
                Text(setting.labelText)
            }
            .disabled(!viewModel.hasDonationHistory)
        }
    }
}

