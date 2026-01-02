//
//  NotificationService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-22.
//

import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCommon
import MastodonLocalization

@MainActor
public final class NotificationService {
    
    public enum UpdateOperation {
        case allAccounts
        case singleAccount(subscriptionObjectID: NSManagedObjectID, userAuthBox: MastodonAuthenticationBox, policy: Mastodon.API.Subscriptions.QueryData.Policy, alerts: Mastodon.API.Subscriptions.QueryData.Alerts)
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
            await updatePushNotificationSubscriptions(deviceToken: token)
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
        let managedObjectContext = PersistenceManager.shared.mainActorManagedObjectContext

        let userAccessToken = pushNotification.accessToken

        let needsCancelSubscription: Bool = try await managedObjectContext.perform {
            // check authentication exists
            let results = AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes.filter { $0.authentication.userAccessToken == userAccessToken }
            return results.first == nil
        }
        
        guard needsCancelSubscription else {
            return
        }
        
        guard let domain = try await domain(for: pushNotification) else { return }
        
        do {
            _ = try await APIService.shared.cancelSubscription(
                domain: domain,
                authorization: .init(accessToken: userAccessToken)
            )
        } catch {
        }
    }
    
    private func domain(for pushNotification: MastodonPushNotification) async throws -> String? {
        let managedObjectContext = PersistenceManager.shared.mainActorManagedObjectContext
        return try await managedObjectContext.perform {
            let subscriptionRequest = NotificationSubscription.sortedFetchRequest
            subscriptionRequest.predicate = NotificationSubscription.predicate(userToken: pushNotification.accessToken)
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
    private func updatePushNotificationSubscriptions(deviceToken: Data) async {
        
        var accountsSubscribed = [String]()
        var hasNewError = false
        for userAuthBox in AuthenticationServiceProvider.shared.mastodonAuthenticationBoxes {
            guard let setting = SettingService.shared.setting(for: userAuthBox) else { continue }
            guard let subscription = setting.activeSubscription else { continue }
            
            do {
                let queryData = Mastodon.API.Subscriptions.QueryData(
                    policy: subscription.policy,
                    alerts: Mastodon.API.Subscriptions.QueryData.Alerts(
                        favourite: subscription.alert.favourite,
                        follow: subscription.alert.follow,
                        reblog: subscription.alert.reblog,
                        mention: subscription.alert.mention,
                        poll: subscription.alert.poll
                    )
                )
                let query = NotificationService.createSubscribeQuery(
                    deviceToken: deviceToken,
                    queryData: queryData,
                    mastodonAuthenticationBox: userAuthBox
                )
                
                let createSubscriptionTask = Task {
                    try await APIService.shared.subscribeToPushNotifications(
                        subscriptionObjectID: subscription.objectID,
                        query: query,
                        mastodonAuthenticationBox: userAuthBox
                    )
                }
                let _ = try await createSubscriptionTask.value
                accountsSubscribed.append(userAuthBox.globallyUniqueUserIdentifier)
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
    
    private func updatePushNotificationSubscription(_ subscriptionObjectID: NSManagedObjectID, for userAuthBox: MastodonAuthenticationBox, policy: Mastodon.API.Subscriptions.QueryData.Policy, alerts: Mastodon.API.Subscriptions.QueryData.Alerts) async throws {
        guard let deviceToken = registrationStatus.value.deviceToken else { return }
        let queryData = Mastodon.API.Subscriptions.QueryData(policy: policy, alerts: alerts)
        let query = NotificationService.createSubscribeQuery(
            deviceToken: deviceToken,
            queryData: queryData,
            mastodonAuthenticationBox: userAuthBox
        )
        let _ = try await APIService.shared.subscribeToPushNotifications(
            subscriptionObjectID: subscriptionObjectID,
            query: query,
            mastodonAuthenticationBox: userAuthBox
        )
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
        case let .singleAccount(subscriptionObjectID, userAuthBox, policy, alerts):
            Task {
                try? await updatePushNotificationSubscription(subscriptionObjectID, for: userAuthBox, policy: policy, alerts: alerts)
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
        
        var disposeBag = Set<AnyCancellable>()
        
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
