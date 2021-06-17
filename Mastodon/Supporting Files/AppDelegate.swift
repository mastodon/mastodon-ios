//
//  AppDelegate.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/22.
//

import os.log
import UIKit
import UserNotifications
import AppShared

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let appContext = AppContext()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppSecret.default.register()
        
        // Update app version info. See: `Settings.bundle`
        UserDefaults.standard.setValue(UIApplication.appVersion(), forKey: "Mastodon.appVersion")
        UserDefaults.standard.setValue(UIApplication.appBuild(), forKey: "Mastodon.appBundle")
        
        // Setup notification
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {        
        return UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }
}

extension AppDelegate {
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        appContext.notificationService.deviceToken.value = deviceToken
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // notification present in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification]", ((#file as NSString).lastPathComponent), #line, #function)
        guard let mastodonPushNotification = AppDelegate.mastodonPushNotification(from: notification) else {
            completionHandler([])
            return
        }
        
        let notificationID = String(mastodonPushNotification.notificationID)
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] notification %s", ((#file as NSString).lastPathComponent), #line, #function, notificationID)
        appContext.notificationService.handle(mastodonPushNotification: mastodonPushNotification)
        completionHandler([.sound])
    }
    
    // response to user action for notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification]", ((#file as NSString).lastPathComponent), #line, #function)
        
        guard let mastodonPushNotification = AppDelegate.mastodonPushNotification(from: response.notification) else {
            completionHandler()
            return
        }
        
        let notificationID = String(mastodonPushNotification.notificationID)
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] notification %s", ((#file as NSString).lastPathComponent), #line, #function, notificationID)
        appContext.notificationService.handle(mastodonPushNotification: mastodonPushNotification)
        appContext.notificationService.requestRevealNotificationPublisher.send(notificationID)
        completionHandler()
    }
    
    private static func mastodonPushNotification(from notification: UNNotification) -> MastodonPushNotification? {
        guard let plaintext = notification.request.content.userInfo["plaintext"] as? Data,
              let mastodonPushNotification = try? JSONDecoder().decode(MastodonPushNotification.self, from: plaintext) else {
            return nil
        }
        
        return mastodonPushNotification
    }
    
}

extension AppContext {
    static var shared: AppContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.appContext
    }
}
