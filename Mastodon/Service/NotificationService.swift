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
import AppShared

final class NotificationService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.app.NotificationService.working-queue")
    
    // input
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    let isNotificationPermissionGranted = CurrentValueSubject<Bool, Never>(false)
    let deviceToken = CurrentValueSubject<Data?, Never>(nil)
        
    // output
    /// [Token: UserID]
    let notificationSubscriptionDict: [String: NotificationViewModel] = [:]
    let hasUnreadPushNotification = CurrentValueSubject<Bool, Never>(false)
    let requestRevealNotificationPublisher = PassthroughSubject<Mastodon.Entity.Notification.ID, Never>()
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService
        
        authenticationService.mastodonAuthentications
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
                os_log(.info, log: .api, "%{public}s[%{public}ld], %{public}s: deviceToken: %s", ((#file as NSString).lastPathComponent), #line, #function, token)
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
    
    func handle(mastodonPushNotification: MastodonPushNotification) {
        hasUnreadPushNotification.value = true
        
        // Subscription maybe failed to cancel when sign-out
        // Try cancel again if receive that kind push notification
        guard let managedObjectContext = authenticationService?.managedObjectContext else { return }
        guard let apiService = apiService else { return }

        managedObjectContext.perform {
            let subscriptionRequest = NotificationSubscription.sortedFetchRequest
            subscriptionRequest.predicate = NotificationSubscription.predicate(userToken: mastodonPushNotification.accessToken)
            let subscriptions = managedObjectContext.safeFetch(subscriptionRequest)
            
            // note: assert setting remove after cancel subscription
            guard let subscription = subscriptions.first else { return }
            guard let setting = subscription.setting else { return }
            let domain = setting.domain
            let userID = setting.userID
            
            let authenticationRequest = MastodonAuthentication.sortedFetchRequest
            authenticationRequest.predicate = MastodonAuthentication.predicate(domain: domain, userID: userID)
            let authentication = managedObjectContext.safeFetch(authenticationRequest).first
            
            guard authentication == nil else {
                // do nothing if still sign-in
                return
            }
            
            // cancel subscription if sign-out
            let accessToken = mastodonPushNotification.accessToken
            let mastodonAuthenticationBox = MastodonAuthenticationBox(
                domain: domain,
                userID: userID,
                appAuthorization: .init(accessToken: accessToken),
                userAuthorization: .init(accessToken: accessToken)
            )
            apiService
                .cancelSubscription(mastodonAuthenticationBox: mastodonAuthenticationBox)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] failed to cancel sign-out user subscription: %s", ((#file as NSString).lastPathComponent), #line, #function, error.localizedDescription)
                    case .finished:
                        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] cancel sign-out user subscription", ((#file as NSString).lastPathComponent), #line, #function)
                    }
                } receiveValue: { _ in
                    // do nothing
                }
                .store(in: &self.disposeBag)
        }
    }
    
}

// MARK: - NotificationViewModel

extension NotificationService {
    final class NotificationViewModel {
        
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
