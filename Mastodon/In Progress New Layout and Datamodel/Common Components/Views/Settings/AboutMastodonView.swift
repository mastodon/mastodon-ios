// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonLocalization
import MastodonSDK
import MastodonCore

struct AboutMastodonView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
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
                // L10n.Scene.Settings.AboutMastodon.clearMediaStorage
                
            }
        }
        .safeAreaInset(edge: .bottom) {
            Text("Mastodon for iOS v\(UIApplication.appVersion()) (\(UIApplication.appBuild()))")
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
