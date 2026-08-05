// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import SwiftUI
import Combine
import MastodonSDK
import MastodonCore

@MainActor
@Observable class NotificationSettingsViewModel {

    private(set) var originalSettings: PushNotificationsSubscription?
    var updatedSettings: PushNotificationsSubscription.PushNotificationsSettings?
    private(set) var isLoading: Bool
    private(set) var isNotificationPermissionGranted: Bool = false
    private let authBox: MastodonAuthenticationBox
    
    @ObservationIgnored private var subscriptions = Set<AnyCancellable>()

    init(authBox: MastodonAuthenticationBox) {
        self.authBox = authBox
        isLoading = true
        isNotificationPermissionGranted = NotificationService.shared.isNotificationPermissionGranted.value
        NotificationService.shared.isNotificationPermissionGranted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notificationsPermitted in
                self?.isNotificationPermissionGranted = notificationsPermitted
            }
            .store(in: &subscriptions)
        
        Task {
            self.originalSettings = await BodegaPersistence.PushNotifications.activeSubscription(for: authBox)
            isLoading = false
        }
    }
    
    var displaySettings: PushNotificationsSubscription.PushNotificationsSettings? {
        guard !isLoading else { return nil }
        return updatedSettings ?? originalSettings?.pending ?? originalSettings?.current ?? .defaultSettings
    }
    
    var settingsToRegister: PushNotificationsSubscription.PushNotificationsSettings? {
        guard !isLoading else { return nil }
        if let updatedSettings {
            return updatedSettings
        }
        if originalSettings?.current == nil && originalSettings?.pending == nil {
            return .defaultSettings
        }
        return nil
    }
    
    func selectPolicy(_ newPolicy: Mastodon.API.Subscriptions.QueryData.Policy) {
        guard let currentSettings = displaySettings else { assertionFailure(); return }
        updatedSettings = PushNotificationsSubscription.PushNotificationsSettings(pushNotificationsFrom: newPolicy, mentions: currentSettings.mentions, boosts: currentSettings.boosts, favorites: currentSettings.favorites, newFollowers: currentSettings.newFollowers, followRequests: currentSettings.followRequests, polls: currentSettings.polls)
    }
    
    func updatePushNotifications(forType notificationAlert: NotificationAlert, newValue: Bool) {
        guard let currentSettings = displaySettings else { assertionFailure(); return }
        let currentMentions = currentSettings.mentions ?? true
        let currentBoosts = currentSettings.boosts ?? true
        let currentFavorites = currentSettings.favorites ?? true
        let currentNewFollowers = currentSettings.newFollowers ?? true

        switch notificationAlert {
        case .mentionsAndReplies:
            updatedSettings = PushNotificationsSubscription.PushNotificationsSettings(
                pushNotificationsFrom: currentSettings.pushNotificationsFrom,
                mentions: newValue,
                boosts: currentBoosts,
                favorites: currentFavorites,
                newFollowers: currentNewFollowers,
                followRequests: currentSettings.followRequests,
                polls: currentSettings.polls)
        case .boosts:
            updatedSettings = PushNotificationsSubscription.PushNotificationsSettings(
                pushNotificationsFrom: currentSettings.pushNotificationsFrom,
                mentions: currentMentions,
                boosts: newValue,
                favorites: currentFavorites,
                newFollowers: currentNewFollowers,
                followRequests: currentSettings.followRequests,
                polls: currentSettings.polls)
        case .favorites:
            updatedSettings = PushNotificationsSubscription.PushNotificationsSettings(
                pushNotificationsFrom: currentSettings.pushNotificationsFrom,
                mentions: currentMentions,
                boosts: currentBoosts,
                favorites: newValue,
                newFollowers: currentNewFollowers,
                followRequests: currentSettings.followRequests,
                polls: currentSettings.polls)
        case .newFollowers:
            updatedSettings = PushNotificationsSubscription.PushNotificationsSettings(
                pushNotificationsFrom: currentSettings.pushNotificationsFrom,
                mentions: currentMentions,
                boosts: currentBoosts,
                favorites: currentFavorites,
                newFollowers: newValue,
                followRequests: currentSettings.followRequests,
                polls: currentSettings.polls)
        }
    }
    
    func receiveFromBinding(_ receiveFrom: NotificationPolicy) -> Binding<Bool> {
        return Binding<Bool>(
            get: {
                NotificationPolicy.fromQueryPolicy(self.displaySettings?.pushNotificationsFrom ?? .all) == receiveFrom
            },
            set: { newValue in
                if newValue {
                    self.selectPolicy(receiveFrom.subscriptionPolicy)
                }
            }
        )
    }
    
    func commitChanges() async throws {
        guard let newSettings = settingsToRegister else { return }
        
        try await BodegaPersistence.PushNotifications.savePendingSubscriptionSettings(newSettings, for: authBox)
        NotificationService.shared.requestUpdate(
            .singleAccount(authBox)
        )
    }
}
