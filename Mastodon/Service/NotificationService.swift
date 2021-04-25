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

final class NotificationService {
    
    var disposeBag = Set<AnyCancellable>()
    
    let workingQueue = DispatchQueue(label: "org.joinmastodon.Mastodon.NotificationService.working-queue")
    
    // input
    weak var apiService: APIService?
    weak var authenticationService: AuthenticationService?
    let isNotificationPermissionGranted = CurrentValueSubject<Bool, Never>(false)
    let deviceToken = CurrentValueSubject<Data?, Never>(nil)
    let mastodonAuthenticationBoxes = CurrentValueSubject<[AuthenticationService.MastodonAuthenticationBox], Never>([])
    
    // output
    /// [Token: UserID]
    let notificationSubscriptionDict: [String: NotificationSubscription] = [:]
    
    init(
        apiService: APIService,
        authenticationService: AuthenticationService
    ) {
        self.apiService = apiService
        self.authenticationService = authenticationService
        
        authenticationService.mastodonAuthentications
            .handleEvents(receiveOutput: { [weak self] mastodonAuthentications in
                guard let self = self else { return }
                
                // request permission when sign-in
                guard !mastodonAuthentications.isEmpty else { return }
                self.requestNotificationPermission()
            })
            .map { authentications -> [AuthenticationService.MastodonAuthenticationBox] in
                return authentications.compactMap { authentication -> AuthenticationService.MastodonAuthenticationBox? in
                    return AuthenticationService.MastodonAuthenticationBox(
                        domain: authentication.domain,
                        userID: authentication.userID,
                        appAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.appAccessToken),
                        userAuthorization: Mastodon.API.OAuth.Authorization(accessToken: authentication.userAccessToken)
                    )
                }
            }
            .assign(to: \.value, on: mastodonAuthenticationBoxes)
            .store(in: &disposeBag)
        
        deviceToken
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deviceToken in
                guard let self = self else { return }
                guard let deviceToken = deviceToken else { return }
                let token = [UInt8](deviceToken).toHexString()
                os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: deviceToken: %s", ((#file as NSString).lastPathComponent), #line, #function, token)
            }
            .store(in: &disposeBag)
        
        Publishers.CombineLatest3(
            isNotificationPermissionGranted,
            deviceToken,
            mastodonAuthenticationBoxes
        )
        .sink { [weak self] isNotificationPermissionGranted, deviceToken, mastodonAuthenticationBoxes in
            guard let self = self else { return }
            guard isNotificationPermissionGranted else { return }
            guard let deviceToken = deviceToken else { return }
            self.registerNotificationSubscriptions(
                deviceToken: [UInt8](deviceToken).toHexString(),
                mastodonAuthenticationBoxes: mastodonAuthenticationBoxes
            )
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
    
    private func registerNotificationSubscriptions(
        deviceToken: String,
        mastodonAuthenticationBoxes: [AuthenticationService.MastodonAuthenticationBox]
    ) {
        for mastodonAuthenticationBox in mastodonAuthenticationBoxes {
            guard let notificationSubscription = dequeueNotificationSubscription(mastodonAuthenticationBox: mastodonAuthenticationBox) else { continue }
            let token = NotificationSubscription.SubscribeToken(
                deviceToken: deviceToken,
                authenticationBox: mastodonAuthenticationBox
            )
            guard let subscription = subscribe(
                notificationSubscription: notificationSubscription,
                token: token
            ) else { continue }
            
            subscription
                .sink { completion in
                    // handle error
                } receiveValue: { response in
                    os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: did create subscription %s with userToken %s", ((#file as NSString).lastPathComponent), #line, #function, response.value.id, mastodonAuthenticationBox.userAuthorization.accessToken)
                    // do nothing
                }
                .store(in: &self.disposeBag)
        }
    }
    
    private func dequeueNotificationSubscription(mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox) -> NotificationSubscription? {
        var _notificationSubscription: NotificationSubscription?
        workingQueue.sync {
            let domain = mastodonAuthenticationBox.domain
            let userID = mastodonAuthenticationBox.userID
            let key = [domain, userID].joined(separator: "@")
            
            if let notificationSubscription = notificationSubscriptionDict[key] {
                _notificationSubscription = notificationSubscription
            } else {
                let notificationSubscription = NotificationSubscription(domain: domain, userID: userID)
                _notificationSubscription = notificationSubscription
            }
        }
        return _notificationSubscription
    }
    
    private func subscribe(
        notificationSubscription: NotificationSubscription,
        token: NotificationSubscription.SubscribeToken
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error>? {
        guard let apiService = self.apiService else { return nil }
        
        if let oldToken = notificationSubscription.token {
            guard oldToken != token else { return nil }
        }
        notificationSubscription.token = token
        
        let appSecret = AppSecret.default
        let endpoint = appSecret.notificationEndpoint + "/" + token.deviceToken
        let p256dh = appSecret.uncompressionNotificationPublicKeyData
        let auth = appSecret.notificationAuth
        
        let query = Mastodon.API.Subscriptions.CreateSubscriptionQuery(
            subscription: Mastodon.API.Subscriptions.QuerySubscription(
                endpoint: endpoint,
                keys: Mastodon.API.Subscriptions.QuerySubscription.Keys(
                    p256dh: p256dh,
                    auth: auth
                )
            ),
            data: Mastodon.API.Subscriptions.QueryData(
                alerts: Mastodon.API.Subscriptions.QueryData.Alerts(
                    favourite: true,
                    follow: true,
                    reblog: true,
                    mention: true,
                    poll: true
                )
            )
        )
        
        return apiService.createSubscription(
            mastodonAuthenticationBox: token.authenticationBox,
            query: query,
            triggerBy: "anyone",
            userID: token.authenticationBox.userID
        )
    }
    
    static func createRandomAuthBytes() -> Data {
        let byteCount = 16
        var bytes = Data(count: byteCount)
        _ = bytes.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, byteCount, $0.baseAddress!) }
        return bytes
    }
}

extension NotificationService {
    final class NotificationSubscription {
        
        var disposeBag = Set<AnyCancellable>()
        
        // input
        let domain: String
        let userID: Mastodon.Entity.Account.ID
        
        var token: SubscribeToken?
        
        init(domain: String, userID: Mastodon.Entity.Account.ID) {
            self.domain = domain
            self.userID = userID
        }
        
        struct SubscribeToken: Equatable {
            
            let deviceToken: String
            let authenticationBox: AuthenticationService.MastodonAuthenticationBox
            // TODO: set other parameter
            
            init(
                deviceToken: String,
                authenticationBox: AuthenticationService.MastodonAuthenticationBox
            ) {
                self.deviceToken = deviceToken
                self.authenticationBox = authenticationBox
            }
            
            static func == (
                lhs: NotificationService.NotificationSubscription.SubscribeToken,
                rhs: NotificationService.NotificationSubscription.SubscribeToken
            ) -> Bool {
                return lhs.deviceToken == rhs.deviceToken &&
                    lhs.authenticationBox.domain == rhs.authenticationBox.domain &&
                    lhs.authenticationBox.userID == rhs.authenticationBox.userID &&
                    lhs.authenticationBox.userAuthorization.accessToken == rhs.authenticationBox.userAuthorization.accessToken
            }
        }
    }
}
