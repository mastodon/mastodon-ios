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
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.Mastodon.NotificationService.working-queue")
    
    // input
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    let isNotificationPermissionGranted = CurrentValueSubject<Bool, Never>(false)
    let deviceToken = CurrentValueSubject<Data?, Never>(nil)
        
    // output
    /// [Token: UserID]
    let notificationSubscriptionDict: [String: NotificationViewModel] = [:]
    let hasUnreadPushNotification = CurrentValueSubject<Bool, Never>(false)
    
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
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: deviceToken: %s", ((#file as NSString).lastPathComponent), #line, #function, token)
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
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
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
    
    func handlePushNotification(notificationID: Mastodon.Entity.Notification.ID) {
        hasUnreadPushNotification.value = true
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
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
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
