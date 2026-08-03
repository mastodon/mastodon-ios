//
//  NotificationService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-22.
//

import UIKit
import Combine
import CoreData // Needed until migration of push notification subscriptions has had time to occur
import CoreDataStack // Needed until migration of push notification subscriptions has had time to occur
import MastodonSDK
import MastodonCommon
import MastodonLocalization

@MainActor
public final class NotificationService {
    
    public enum UpdateOperation {
        case allAccounts
        case singleAccount(MastodonAuthenticationBox)
    }
    
    public enum PushNotificationRegistrationStatus {
        case registering
        case errorRegisteringWithAPNS(Error)
        case registrationTokenReceived(Data)
        case subscriptionsUpdated(deviceToken: Data, subscribedAccounts: [String])
        case errorUpdatingSubscriptions(Error, deviceToken: Data)
        
        var deviceToken: Data? {
            switch self {
            case .registering, .errorRegisteringWithAPNS(_):
                return nil
            case .registrationTokenReceived(let token), .subscriptionsUpdated(let token, _), .errorUpdatingSubscriptions(_, let token):
                return token
            }
        }
    }
    
    @MainActor public static var isMigratingSettings = false
    
    public static let shared = { NotificationService() }()
    
    public static let unreadShortcutItemIdentifier = "org.joinmastodon.app.NotificationService.unread-shortcut"
    
    private var disposeBag = Set<AnyCancellable>()
    
    private let workingQueue = DispatchQueue(label: "org.joinmastodon.app.NotificationService.working-queue")
    private var subscriptionUpdateQueue = [UpdateOperation]()
    private var currentUpdateInProgress: UpdateOperation? = nil {
        didSet {
            if currentUpdateInProgress == nil {
                doNextUpdate()
            }
        }
    }
    
    // input
    public let registrationStatus = CurrentValueSubject<PushNotificationRegistrationStatus, Never>(.registering)
    public let isNotificationPermissionGranted = CurrentValueSubject<Bool, Never>(false)
    public let applicationIconBadgeNeedsUpdate = CurrentValueSubject<Void, Never>(Void())
        
    // output
    /// [Token: NotificationViewModel]
    public let notificationSubscriptionDict: [String: NotificationViewModel] = [:]
    public let unreadNotificationCountDidUpdate = CurrentValueSubject<Void, Never>(Void())
    public let requestRevealNotificationPublisher = PassthroughSubject<MastodonPushNotification, Never>()
    
    private init() {
        Publishers.CombineLatest(
            AuthenticationServiceProvider.shared.currentActiveUser,
            registrationStatus
            )
            .sink(receiveValue: { [weak self] auth, registrationStatus in
                guard let self = self else { return }
                
                // request permission when sign-in
                switch (auth, registrationStatus) {
                case (nil, _):
                    break
                case (_, .registrationTokenReceived), (_, .errorUpdatingSubscriptions):
                    self.requestUpdate(.allAccounts)
                        
                case (_, .subscriptionsUpdated(_, let subscribedAccounts)):
                    guard let userIdentifier = auth?.globallyUniqueUserIdentifier else { return }
                    if !subscribedAccounts.contains(userIdentifier) {
                        self.requestUpdate(.allAccounts)
                    }
                case (_, .registering), (_, .errorRegisteringWithAPNS):
                    break
                }
            })
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            AuthenticationServiceProvider.shared.$mastodonAuthenticationBoxes,
            applicationIconBadgeNeedsUpdate
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] mastodonAuthenticationBoxes, _ in
            guard let self = self else { return }
            
            var count = 0
            for authenticationBox in mastodonAuthenticationBoxes {
                count += UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: authenticationBox.userAuthorization.accessToken)
            }
            
            UserDefaults.shared.notificationBadgeCount = count
            UNUserNotificationCenter.current().setBadgeCount(count)
            Task { @MainActor in
                UIApplication.shared.shortcutItems = try? await self.unreadApplicationShortcutItems()
            }
            
            self.unreadNotificationCountDidUpdate.send()
        }
        .store(in: &disposeBag)
    }
    
}

extension NotificationService {
    private func requestNotificationPermissionAndUpdateSubscriptions() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard isNotificationPermissionGranted.value != granted else { return }
        isNotificationPermissionGranted.value = granted
        switch (granted, registrationStatus.value) {
        case (true, .registrationTokenReceived), (true, .errorUpdatingSubscriptions), (true, .subscriptionsUpdated):
            guard let token = registrationStatus.value.deviceToken else { return }
            try await updatePushNotificationSubscriptions(deviceToken: token)
        case (true, .errorRegisteringWithAPNS):
            UIApplication.shared.registerForRemoteNotifications()
        case (true, .registering):
            break
        case (false, _):
            break
        }
    }
}

extension NotificationService {
    public func unreadApplicationShortcutItems() async throws -> [UIApplicationShortcutItem] {

        var items: [UIApplicationShortcutItem] = []
        for authBox in AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes {
            guard let account = authBox.authentication.cachedAccount() else { continue }
            let accessToken = authBox.authentication.userAccessToken
            let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
            guard count > 0 else { continue }

            let title = "@\(account.acctWithDomain)"
            let subtitle = L10n.A11y.Plural.Count.Unread.notification(count)

            let item = UIApplicationShortcutItem(
                type: NotificationService.unreadShortcutItemIdentifier,
                localizedTitle: title,
                localizedSubtitle: subtitle,
                icon: nil,
                userInfo: [
                    "accessToken": accessToken as NSSecureCoding
                ]
            )
            items.append(item)
        }
        return items
    }}

extension NotificationService {
    
    public func dequeueNotificationViewModel(
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> NotificationViewModel? {
        var _notificationSubscription: NotificationViewModel?
        workingQueue.sync {
            let domain = mastodonAuthenticationBox.domain
            let userID = mastodonAuthenticationBox.userID
            let key = [domain, userID].joined(separator: "@")
            
            if let notificationSubscription = notificationSubscriptionDict[key] {
                _notificationSubscription = notificationSubscription
            } else {
                let notificationSubscription = NotificationViewModel(domain: domain, userID: userID)
                _notificationSubscription = notificationSubscription
            }
        }
        return _notificationSubscription
    }
    
    public func handle(
        pushNotification: MastodonPushNotification
    ) {
        defer {
            unreadNotificationCountDidUpdate.send()
        }

        Task {
            // trigger notification timeline update
            try? await fetchLatestNotifications(pushNotification: pushNotification)
            
            // cancel sign-out account push notification subscription 
            try? await cancelSubscriptionForDetachedAccount(pushNotification: pushNotification)
        }   // end Task
    }
    
}

extension NotificationService {
    public func clearNotificationCountForActiveUser() {
        if let accessToken = AuthenticationServiceProvider.shared.currentActiveUser.value?.userAuthorization.accessToken {
            UserDefaults.shared.setNotificationCountWithAccessToken(accessToken: accessToken, value: 0)
        }
        
        applicationIconBadgeNeedsUpdate.send()
    }
}

extension NotificationService {
    private func fetchLatestNotifications(
        pushNotification: MastodonPushNotification
    ) async throws {
        guard let authenticationBox = authenticationBox(for: pushNotification) else { return }
        
        _ = try await APIService.shared.notifications(
            olderThan: nil,
            scope: .everything,
            authenticationBox: authenticationBox
        )
    }
    
    private func cancelSubscriptionForDetachedAccount(
        pushNotification: MastodonPushNotification
    ) async throws {
        // Subscription maybe failed to cancel when sign-out
        // Try cancel again if receive that kind push notification

        let userAccessToken = pushNotification.accessToken

        let subscribedUser = AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.first(where: { $0.authentication.userAccessToken == userAccessToken })
       
        guard subscribedUser == nil else {
            return
        }
        
        guard let domain = try await domain(for: pushNotification) else { return }
        
        do {
            _ = try await APIService.shared.cancelSubscription(
                domain: domain,
                authorization: .init(accessToken: userAccessToken, domain: domain)
            )
        } catch {
        }
    }
    
    private func domain(for pushNotification: MastodonPushNotification) async throws -> String? {
        let managedObjectContext = PersistenceManager.shared.mainActorManagedObjectContext
        return try await managedObjectContext.perform {
            let subscriptionRequest = Subscription.sortedFetchRequest
            subscriptionRequest.predicate = Subscription.predicate(userToken: pushNotification.accessToken)
            let subscriptions = managedObjectContext.safeFetch(subscriptionRequest)
            
            // note: assert setting not remove after sign-out
            guard let subscription = subscriptions.first else { return nil }
            guard let setting = subscription.setting else { return nil }
            let domain = setting.domain
            
            return domain
        }
    }
    
    private func authenticationBox(for pushNotification: MastodonPushNotification) -> MastodonAuthenticationBox? {
        return AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.first { $0.authentication.userAccessToken == pushNotification.accessToken
        }
    }
    
}

extension NotificationService {
    
    private func didUpdatePushNotificationSubscription(_ subscription: Mastodon.Entity.Subscription, receiveFrom: Mastodon.API.Subscriptions.QueryData.Policy, for authBox: MastodonAuthenticationBox) async throws {
        try await BodegaPersistence.PushNotifications.didRegisterSubscription(subscription, receiveFrom: receiveFrom, for: authBox)
    }
    
    private func currentPushNotificationSubscriptions() async throws -> [ (MastodonAuthenticationBox, PushNotificationsSubscription.PushNotificationsSettings) ] {
        guard !NotificationService.isMigratingSettings else { return [] }
        NotificationService.isMigratingSettings = true
        try await migrateSettingsIfNeeded()
        NotificationService.isMigratingSettings = false
        var result = [ (MastodonAuthenticationBox, PushNotificationsSubscription.PushNotificationsSettings) ]()
        for authBox in AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes {
            let subscriptionInfo = await BodegaPersistence.PushNotifications.activeSubscription(for: authBox)
            guard let subscription = subscriptionInfo?.pending ?? subscriptionInfo?.current else { continue }
            result.append((authBox, subscription))
        }
        return result
    }
    
    private func migrateSettingsIfNeeded() async throws {
        guard !UserDefaults.standard.didMigratePushNotifications else { return }
        for userAuthBox in AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes {
            if let legacySetting = SettingService.shared.setting(for: userAuthBox) {
                let recentLanguages = legacySetting.recentLanguages
                try? await BodegaPersistence.RecentLanguages.updateRecentLanguages(recentLanguages, for: userAuthBox)
                
                guard let legacySubscription = legacySetting.activeSubscription else { continue }
                
                let receiveFrom = legacySubscription.notificationPolicy
                let newSubscription = PushNotificationsSubscription.PushNotificationsSettings(pushNotificationsFrom: receiveFrom ?? .all,
                                                                                              mentions: legacySubscription.alert.mention,
                                                                                              boosts: legacySubscription.alert.reblog,
                                                                                              favorites: legacySubscription.alert.favourite,
                                                                                              newFollowers: legacySubscription.alert.follow,
                                                                                              followRequests: legacySubscription.alert.followRequest,
                                                                                              polls: legacySubscription.alert.poll)
                try await BodegaPersistence.PushNotifications.savePendingSubscriptionSettings(newSubscription, for: userAuthBox)
            }
        }
        for userAuthBox in AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes {
            SettingService.shared.deleteSetting(for: userAuthBox)
        }
        UserDefaults.standard.didMigratePushNotifications = true
    }
    
    private func updatePushNotificationSubscriptions(deviceToken: Data) async throws {
        
        var accountsSubscribed = [String]()
        var hasNewError = false
        let subscriptions = try await currentPushNotificationSubscriptions()
        for (userAuthBox, subscription) in subscriptions {
            do {
                let queryData = Mastodon.API.Subscriptions.QueryData(
                    policy: subscription.pushNotificationsFrom,
                    alerts: subscription.alerts
                )
                let query = NotificationService.createSubscribeQuery(
                    deviceToken: deviceToken,
                    queryData: queryData,
                    mastodonAuthenticationBox: userAuthBox
                )
                
                let createSubscriptionTask = Task {
                    try await APIService.shared.subscribeToPushNotifications(
                        query: query,
                        mastodonAuthenticationBox: userAuthBox
                    )
                }
                let newSubscription = try await createSubscriptionTask.value
                accountsSubscribed.append(userAuthBox.globallyUniqueUserIdentifier)
                try await didUpdatePushNotificationSubscription(newSubscription, receiveFrom: subscription.pushNotificationsFrom, for: userAuthBox)
#if DEBUG
                print("successful register of push notifications for \(String(describing: userAuthBox.cachedAccount?.displayNameWithFallback))")
#endif
            } catch {
#if DEBUG
                print("failed register of push notifications for \(String(describing: userAuthBox.cachedAccount?.displayNameWithFallback))")
#endif
                registrationStatus.send(.errorUpdatingSubscriptions(error, deviceToken: deviceToken))
                hasNewError = true
                do {
                    try await Task.sleep(nanoseconds: 3 * UInt64.nanosPerUnit)
                } catch {
                }
            }
        }
        if accountsSubscribed.isEmpty && hasNewError {
            return
        } else {
            registrationStatus.send(.subscriptionsUpdated(deviceToken: deviceToken, subscribedAccounts: accountsSubscribed))
        }
    }
    
    private func updatePushNotificationSubscription(for userAuthBox: MastodonAuthenticationBox) async throws {
        guard let deviceToken = registrationStatus.value.deviceToken else { throw APIService.APIError.explicit(.authenticationMissing) }
        guard let subscriptionInfo = await BodegaPersistence.PushNotifications.activeSubscription(for: userAuthBox) else { return }
        guard let subscription = subscriptionInfo.pending ?? subscriptionInfo.current else { return }
        let queryData = Mastodon.API.Subscriptions.QueryData(policy: subscription.pushNotificationsFrom, alerts: subscription.alerts)
        let query = NotificationService.createSubscribeQuery(
            deviceToken: deviceToken,
            queryData: queryData,
            mastodonAuthenticationBox: userAuthBox
        )
        let updatedSubscription = try await APIService.shared.subscribeToPushNotifications(
            query: query,
            mastodonAuthenticationBox: userAuthBox
        )
        try await BodegaPersistence.PushNotifications.didRegisterSubscription(updatedSubscription, receiveFrom: subscription.pushNotificationsFrom, for: userAuthBox)
    }
}

extension NotificationService {
    public func requestUpdate(_ updateOperation: UpdateOperation) {
        subscriptionUpdateQueue.append(updateOperation)
        doNextUpdate()
    }
    
    private func doNextUpdate() {
        guard currentUpdateInProgress == nil else { return }
        guard !subscriptionUpdateQueue.isEmpty else { return }
        currentUpdateInProgress = subscriptionUpdateQueue.removeFirst()
        switch currentUpdateInProgress {
        case .allAccounts:
            Task {
                try? await requestNotificationPermissionAndUpdateSubscriptions()
                currentUpdateInProgress = nil
            }
        case .singleAccount(let userAuthBox):
            Task {
                try? await updatePushNotificationSubscription(for: userAuthBox)
                currentUpdateInProgress = nil
            }
        case nil:
            break
        }
    }
}

// MARK: - NotificationViewModel

extension NotificationService {
    public final class NotificationViewModel {
        // input
        let domain: String
        let userID: Mastodon.Entity.Account.ID
        
        // output
        
        init(domain: String, userID: Mastodon.Entity.Account.ID) {
            self.domain = domain
            self.userID = userID
        }
    }
}

extension NotificationService {
    public static func createSubscribeQuery(
        deviceToken: Data,
        queryData: Mastodon.API.Subscriptions.QueryData,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> Mastodon.API.Subscriptions.CreateSubscriptionQuery {
        let deviceToken = [UInt8](deviceToken).toHexString()
        
        let appSecret = AppSecret.default
        let endpoint = appSecret.notificationEndpoint + "/" + deviceToken
        let p256dh = appSecret.notificationPublicKey.x963Representation
        let auth = appSecret.notificationAuth

        let query = Mastodon.API.Subscriptions.CreateSubscriptionQuery(
            subscription: Mastodon.API.Subscriptions.QuerySubscription(
                endpoint: endpoint,
                keys: Mastodon.API.Subscriptions.QuerySubscription.Keys(
                    p256dh: p256dh,
                    auth: auth
                )
            ),
            data: queryData
        )

        return query
    }
    
}

public struct PushNotificationsSubscription: Codable {
    public let current: PushNotificationsSettings?
    public let pending: PushNotificationsSettings?
    
    public init(current: PushNotificationsSettings?, pending: PushNotificationsSettings?) {
        self.current = current
        self.pending = pending
    }
    
    public struct PushNotificationsSettings: Codable {
        // NOTE: adding items here requires updating the equivalency logic in BodegaPersistence.didRegisterSubscription()
        public let pushNotificationsFrom: Mastodon.API.Subscriptions.QueryData.Policy
        public let mentions: Bool?
        public let boosts: Bool?
        public let favorites: Bool?
        public let newFollowers: Bool?
        public let followRequests: Bool?
        public let polls: Bool?
        
        public init(pushNotificationsFrom: Mastodon.API.Subscriptions.QueryData.Policy, mentions: Bool?, boosts: Bool?, favorites: Bool?, newFollowers: Bool?, followRequests: Bool?, polls: Bool?) {
            self.pushNotificationsFrom = pushNotificationsFrom
            self.mentions = mentions
            self.boosts = boosts
            self.favorites = favorites
            self.newFollowers = newFollowers
            self.followRequests = followRequests
            self.polls = polls
        }
        
        public static let defaultSettings = PushNotificationsSubscription.PushNotificationsSettings(pushNotificationsFrom: .all, mentions: true, boosts: true, favorites: true, newFollowers: true, followRequests: true, polls: true)
        
        public var alerts: Mastodon.API.Subscriptions.QueryData.Alerts {
            Mastodon.API.Subscriptions.QueryData.Alerts(
                favourite: favorites,
                follow: newFollowers,
                reblog: boosts,
                mention: mentions,
                poll: polls
            )
        }
    }
}

extension CoreDataSubscription {
    var notificationPolicy: Mastodon.API.Subscriptions.QueryData.Policy? {
        guard let policy else { return nil }
        switch policy {
        case .all:
            return .all
        case .followed:
            return .followed
        case .follower:
            return .follower
        case .noone:
            return .noone
        case ._other(_):
            return .noone
        }
    }
}
