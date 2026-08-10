// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization
import MastodonAsset
import MastodonSDK
import MastodonCore

struct AboutMastodonView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @State private var cacheOverview = CacheOverviewManager()
    let authBox: MastodonAuthenticationBox
    
    var body: some View {
        Form {
            Section {
                // Even More Settings
                NavigationRow(label: L10n.Scene.Settings.AboutMastodon.moreSettings, sublabel: nil)
                    .onTapGesture {
                        let url = Mastodon.API.profileSettingsURL(domain: authBox.domain)
                        navigator.openUrl(url, afterDeconflictionDelay: false)
                    }
                
                // Contribute to Mastodon
                NavigationRow(label: L10n.Scene.Settings.AboutMastodon.contributeToMastodon, sublabel: nil)
                    .onTapGesture {
                        if let url = URL(string: "https://github.com/mastodon/mastodon-ios") {
                            navigator.openUrl(url, afterDeconflictionDelay: false)
                        }
                    }
                
                // Privacy Policy
                NavigationRow(label: L10n.Scene.Settings.AboutMastodon.privacyPolicy, sublabel: nil)
                    .onTapGesture {
                        if let url = authBox.authentication.privacyPolicyURL {
                            navigator.openUrl(url, afterDeconflictionDelay: false)
                        }
                    }
            }
            
            Section {
                // Clear Media Storage
                ActionRow(label: L10n.Scene.Settings.AboutMastodon.clearMediaStorage, sublabel: cacheSizeLabel, showSpinnerWhenDisabled: true)
                    .onTapGesture {
                        cacheOverview.purgeAllCaches()
                    }
                    .disabled(!cacheOverview.currentState.isReady)
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("Mastodon for iOS v\(UIApplication.appVersion()) (\(UIApplication.appBuild()))")
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
    
    var cacheSizeLabel: String? {
        switch cacheOverview.currentState {
        case .calculating, .purging:
            return nil
        case .ready(let calculatedBytes):
            guard let calculatedBytes else { return nil }
            return cacheOverview.byteCountFormatter.string(fromByteCount: Int64(calculatedBytes))
        }
    }
}

struct ActionRow: View {
    let label: String
    let sublabel: String?
    let showSpinnerWhenDisabled: Bool
    @Environment(\.isEnabled) var enabled
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(enabled ? Asset.Colors.accent.swiftUIColor : .secondary)
            Spacer()
            if enabled, let sublabel {
                Text(sublabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if showSpinnerWhenDisabled {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .contentShape(Rectangle())
    }
}
