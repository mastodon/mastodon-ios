// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset
import MastodonLocalization
import MastodonCore

struct NotificationSettingsView: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(NotificationSettingsViewModel.self) var viewModel
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        Form {
            if !viewModel.isNotificationPermissionGranted {
                Section {
                    NotificationsDisabledMessageRow()
                        .onTapGesture {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                }
            }
            
            Section {
                // Get notifications from...
                NavigationRow(label: L10n.Scene.Settings.Notifications.Policy.title, sublabel: viewModel.displaySettings?.pushNotificationsFrom.title)
                    .onTapGesture {
                        navigator.push(.settings(.notificationsReceiveFromPicker))
                    }
                    .disabled(!viewModel.isNotificationPermissionGranted)
            }
            
            Section {
            // mentions and replies
                // boosts
                // favorites
                // new followers
            }
        }
        .navigationTitle(title)
        .task {
            NotificationService.shared.requestUpdate(.allAccounts)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                NotificationService.shared.requestUpdate(.allAccounts)
            }
        }
        .onDisappear {
            Task {
                do {
                    try await viewModel.commitChanges()
                } catch {
                    navigator.didReceiveError(error)
                }
            }
        }
    }
    
    var title: String {
        if AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.count > 1, let username = AuthenticationObserver.shared.currentActiveUser?.cachedAccount?.acctWithDomain {
            return username
        } else {
            return L10n.Scene.Settings.Notifications.title
        }
    }
}

struct NotificationsDisabledMessageRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: spacingBetweenGutterAndContent) {
            NotificationIconView(systemName: "app.badge.fill", color: Asset.Colors.accent.swiftUIColor)

            VStack(alignment: .leading, spacing: standardPadding) {
                Text(L10n.Scene.Settings.Notifications.Disabled.notificationHint)
                Text(L10n.Scene.Settings.Notifications.Disabled.goToSettings)
                    .fontWeight(.semibold)
                    .foregroundStyle(Asset.Colors.accent.swiftUIColor)
            }
        }
    }
}

struct NotificationReceiveFromPicker: View {
    @Environment(MastodonNavigationRouter.self) var navigator
    @Environment(NotificationSettingsViewModel.self) var viewModel
    
    var body: some View {
        Form {
            ForEach(NotificationPolicy.allCases, id: \.self) { option in
                SelectionRow(label: option.title, isSelected: viewModel.receiveFromBinding(option), onSelect: {                    navigator.pop() })
            }
        }
    }
}
