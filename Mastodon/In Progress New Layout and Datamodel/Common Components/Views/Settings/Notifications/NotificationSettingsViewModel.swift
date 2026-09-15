// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import SwiftUI
import Combine
import MastodonSDK
import MastodonCore
import MastodonLocalization

@MainActor
@Observable class NotificationSettingsViewModel {

    private(set) var originalSettings: PushNotificationsSubscription?
    private(set) var adminNotificationFilterSettings: AdminNotificationFilterSettings?
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
            self.adminNotificationFilterSettings = await BodegaPersistence.Notifications.currentPreferences(for: authBox)
            isLoading = false
        }
    }
    
    var displaySettings: PushNotificationsSubscription.PushNotificationsSettings? {
        guard !isLoading else { return nil }
        return updatedSettings ?? originalSettings?.pending ?? originalSettings?.current ?? .defaultSettings
    }
    
    var availableNotificationTypes: [NotificationAlert] {
        let quotesAvailable = authBox.authentication.instanceConfiguration?.isAvailable(.quotePosts) ?? false
        return NotificationAlert.allCases.filter { alert in
            !alert.isAdminOnly && (quotesAvailable || !alert.requiresQuotePostFeature)
        }
    }
    
    var availableAdminNotificationTypes: [NotificationAlert] {
        guard authBox.hasAdminPermissions else { return [] }
        return NotificationAlert.allCases.filter { $0.isAdminOnly }
    }
    
    func isFilteredOutInNotificationsTab(_ type: NotificationAlert) -> Bool {
        switch type {
        case .adminReports:
            !(adminNotificationFilterSettings?.showsReports ?? true)
        case .adminSignUps:
            !(adminNotificationFilterSettings?.showsSignUps ?? true)
        default: false
        }
    }
    
    var settingsToRegister: PushNotificationsSubscription.PushNotificationsSettings? {
        guard !isLoading else { return nil }
        if let updatedSettings {
            return updatedSettings
        }
        return nil
    }
    
    func selectPolicy(_ newPolicy: Mastodon.API.Subscriptions.QueryData.Policy) {
        guard var displayedSettings = displaySettings else { assertionFailure(); return }
        displayedSettings.pushNotificationsFrom = newPolicy
        updatedSettings = displayedSettings
    }
    
    func updatePushNotifications(forType notificationAlert: NotificationAlert, newValue: Bool) {
        guard var displayedSettings = displaySettings else { assertionFailure(); return }
        displayedSettings[keyPath: notificationAlert.settingsKeyPath] = newValue
        updatedSettings = displayedSettings
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
    
    func notificationTypeToggleBinding(_ notificationType: NotificationAlert) -> Binding<Bool> {
        Binding<Bool> (
            get: {
                guard let displaySettings = self.displaySettings else { return false }
                return displaySettings.alerts(applying: self.adminNotificationFilterSettings)[keyPath: notificationType.alertsKeyPath] ?? false
            },
            set: { newValue in
                self.updatePushNotifications(forType: notificationType, newValue: newValue)
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

enum NotificationPolicy: Hashable, CaseIterable {
    case anyone
    case followers
    case follow
    case noone
    
    var title: String {
        switch self {
        case .anyone:
            return L10n.Scene.Settings.Notifications.Policy.anyone
        case .followers:
            return L10n.Scene.Settings.Notifications.Policy.followers
        case .follow:
            return L10n.Scene.Settings.Notifications.Policy.follow
        case .noone:
            return L10n.Scene.Settings.Notifications.Policy.noone
        }
    }
    
    var subscriptionPolicy: Mastodon.API.Subscriptions.Policy {
        switch self {
        case .anyone:
            return .all
        case .followers:
            return .follower
        case .follow:
            return .followed
        case .noone:
            return .noone
        }
    }
    
    static func fromQueryPolicy(_ policy: Mastodon.API.Subscriptions.QueryData.Policy) -> Self {
        switch policy {
        case ._other: return .anyone
        case .all: return .anyone
        case .followed: return .follow
        case .follower: return .followers
        case .noone: return .noone
        }
    }
}

enum NotificationAlert: Hashable, CaseIterable {
    case newFollowers
    case followRequests
    case boosts
    case favorites
    case mentionsAndReplies
    case quotes
    case polls
    case newPosts
    case edits
    case editsToQuotedPosts
    case adminReports
    case adminSignUps
    
    var title: String {
        switch self {
            
        case .mentionsAndReplies:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.mentionsAndReplies
        case .boosts:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.boosts
        case .favorites:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.favourites
        case .newFollowers:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.newFollowers
        case .followRequests:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.followRequests
        case .quotes:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.quotes
        case .polls:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.polls
        case .newPosts:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.newPosts
        case .edits:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.edits
        case .editsToQuotedPosts:
            L10nLookup.Scene.Settings.Notifications.PushNotificationTypes.editsToQuotedPosts
        case .adminReports:
            L10n.Scene.Notification.AdminFilter.Reports.title
        case .adminSignUps:
            L10n.Scene.Notification.AdminFilter.Signups.title
        }
    }
    
    var settingsKeyPath: WritableKeyPath<PushNotificationsSubscription.PushNotificationsSettings, Bool?> {
        switch self {
        case .mentionsAndReplies: \.mentions
        case .boosts: \.boosts
        case .favorites: \.favorites
        case .newFollowers: \.newFollowers
        case .followRequests: \.followRequests
        case .quotes: \.quotes
        case .polls: \.polls
        case .newPosts: \.newPosts
        case .edits: \.edits
        case .editsToQuotedPosts: \.editsToQuotedPosts
        case .adminReports: \.adminReports
        case .adminSignUps: \.adminSignUps
        }
    }
    
    var alertsKeyPath: KeyPath<Mastodon.API.Subscriptions.QueryData.Alerts, Bool?> {
        switch self {
        case .newFollowers: \.follow
        case .followRequests: \.followRequest
        case .boosts: \.reblog
        case .favorites: \.favourite
        case .mentionsAndReplies: \.mention
        case .quotes: \.quote
        case .polls: \.poll
        case .newPosts: \.status
        case .edits: \.update
        case .editsToQuotedPosts: \.quotedUpdate
        case .adminReports: \.adminReport
        case .adminSignUps: \.adminSignUp
        }
    }
    
    var isAdminOnly: Bool {
        switch self {
        case .adminReports, .adminSignUps: return true
        default: return false
        }
    }
    
    var requiresQuotePostFeature: Bool {
        switch self {
        case .quotes, .editsToQuotedPosts: return true
        default: return false
        }
    }
}
