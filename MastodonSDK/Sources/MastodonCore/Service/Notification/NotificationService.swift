//
//  NotificationService.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-22.
//

import os.log
import UIKit
import Combine
import CoreData
import CoreDataStack
import MastodonSDK
import MastodonCommon
import MastodonLocalization

public final class NotificationService {
    
    public static let unreadShortcutItemIdentifier = "com.emerge.mastodon.NotificationService.unread-shortcut"
    
    var disposeBag = Set<AnyCancellable>()
    
    let workingQueue = DispatchQueue(label: "com.emerge.mastodon.NotificationService.working-queue")
    
    // input
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    public let isNotificationPermissionGranted = CurrentValueSubject<Bool, Never>(false)
    public let deviceToken = CurrentValueSubject<Data?, Never>(nil)
    public let applicationIconBadgeNeedsUpdate = CurrentValueSubject<Void, Never>(Void())
        
    // output
    /// [Token: NotificationViewModel]
    public let notificationSubscriptionDict: [String: NotificationViewModel] = [:]
    public let unreadNotificationCountDidUpdate = CurrentValueSubject<Void, Never>(Void())
    public let requestRevealNotificationPublisher = PassthroughSubject<MastodonPushNotification, Never>()
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService
        
        authenticationService.$mastodonAuthentications
            .sink(receiveValue: { [weak self] mastodonAuthentications in
                guard let self = self else { return }
                
                // request permission when sign-in
                guard !mastodonAuthentications.isEmpty else { return }
                self.requestNotificationPermission()
            })
            .store(in: &disposeBag)
        
        deviceToken
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deviceToken in
                guard let _ = self else { return }
                guard let deviceToken = deviceToken else { return }
                let token = [UInt8](deviceToken).toHexString()
                let logger = Logger(subsystem: "DeviceToken", category: "NotificationService")
                logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): deviceToken: \(token)")
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest(
            authenticationService.$mastodonAuthenticationBoxes,
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
            UIApplication.shared.applicationIconBadgeNumber = count
            Task { @MainActor in
                UIApplication.shared.shortcutItems = try? await self.unreadApplicationShortcutItems()
            }
            
            self.unreadNotificationCountDidUpdate.send()
        }
        .store(in: &disposeBag)
    }
    
}

extension NotificationService {
    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            guard let self = self else { return }
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: request notification permission: %s", ((#file as NSString).lastPathComponent), #line, #function, granted ? "granted" : "fail")

            self.isNotificationPermissionGranted.value = granted
            
            if let _ = error {
                // Handle the error here.
            }
            
            // Enable or disable features based on the authorization.
        }
    }
}

extension NotificationService {
    public func unreadApplicationShortcutItems() async throws -> [UIApplicationShortcutItem] {
        guard let authenticationService = self.authenticationService else { return [] }
        let managedObjectContext = authenticationService.managedObjectContext
        return try await managedObjectContext.perform {
            var items: [UIApplicationShortcutItem] = []
            for object in authenticationService.mastodonAuthentications {
                guard let authentication = managedObjectContext.object(with: object.objectID) as? MastodonAuthentication else { continue }
                let accessToken = authentication.userAccessToken
                let count = UserDefaults.shared.getNotificationCountWithAccessToken(accessToken: accessToken)
                guard count > 0 else { continue }
                
                let title = "@\(authentication.user.acctWithDomain)"
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
        }
    }
}

extension NotificationService {
    
    func dequeueNotificationViewModel(
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
        guard let authenticationService = self.authenticationService else { return }
        if let accessToken = authenticationService.mastodonAuthenticationBoxes.first?.userAuthorization.accessToken {
            UserDefaults.shared.setNotificationCountWithAccessToken(accessToken: accessToken, value: 0)
        }
        
        applicationIconBadgeNeedsUpdate.send()
    }
}

extension NotificationService {
    private func fetchLatestNotifications(
        pushNotification: MastodonPushNotification
    ) async throws {
        guard let apiService = apiService else { return }
        guard let authenticationBox = try await authenticationBox(for: pushNotification) else { return }
        
        _ = try await apiService.notifications(
            maxID: nil,
            scope: .everything,
            authenticationBox: authenticationBox
        )
    }
    
    private func cancelSubscriptionForDetachedAccount(
        pushNotification: MastodonPushNotification
    ) async throws {
        // Subscription maybe failed to cancel when sign-out
        // Try cancel again if receive that kind push notification
        guard let managedObjectContext = authenticationService?.managedObjectContext else { return }
        guard let apiService = apiService else { return }

        let userAccessToken = pushNotification.accessToken

        let needsCancelSubscription: Bool = try await managedObjectContext.perform {
            // check authentication exists
            let authenticationRequest = MastodonAuthentication.sortedFetchRequest
            authenticationRequest.predicate = MastodonAuthentication.predicate(userAccessToken: userAccessToken)
            return managedObjectContext.safeFetch(authenticationRequest).first == nil
        }
        
        guard needsCancelSubscription else {
            return
        }
        
        guard let domain = try await domain(for: pushNotification) else { return }
        
        do {
            _ = try await apiService.cancelSubscription(
                domain: domain,
                authorization: .init(accessToken: userAccessToken)
            )
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] cancel sign-out user subscription", ((#file as NSString).lastPathComponent), #line, #function)
        } catch {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] failed to cancel sign-out user subscription: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
        }
    }
    
    private func domain(for pushNotification: MastodonPushNotification) async throws -> String? {
        guard let authenticationService = self.authenticationService else { return nil }
        let managedObjectContext = authenticationService.managedObjectContext
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
    
    private func authenticationBox(for pushNotification: MastodonPushNotification) async throws -> MastodonAuthenticationBox? {
        guard let authenticationService = self.authenticationService else { return nil }
        let managedObjectContext = authenticationService.managedObjectContext
        return try await managedObjectContext.perform {
            let request = MastodonAuthentication.sortedFetchRequest
            request.predicate = MastodonAuthentication.predicate(userAccessToken: pushNotification.accessToken)
            request.fetchLimit = 1
            guard let authentication = managedObjectContext.safeFetch(request).first else { return nil }
            
            return MastodonAuthenticationBox(
                authenticationRecord: .init(objectID: authentication.objectID),
                domain: authentication.domain,
                userID: authentication.userID,
                appAuthorization: .init(accessToken: authentication.appAccessToken),
                userAuthorization: .init(accessToken: authentication.userAccessToken)
            )
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

extension NotificationService.NotificationViewModel {
    func createSubscribeQuery(
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
