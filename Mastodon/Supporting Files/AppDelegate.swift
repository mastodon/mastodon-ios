//
//  AppDelegate.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/1/22.
//

import os.log
import UIKit
import AppShared

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let appContext = AppContext()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        AppSecret.default.register()
        
        // Update app version info. See: `Settings.bundle`
        UserDefaults.standard.setValue(UIApplication.appVersion(), forKey: "Mastodon.appVersion")
        UserDefaults.standard.setValue(UIApplication.appBuild(), forKey: "Mastodon.appBundle")
        
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
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification]", ((#file as NSString).lastPathComponent), #line, #function)
        if let plaintext = notification.request.content.userInfo["plaintext"] as? Data,
           let mastodonPushNotification = try? JSONDecoder().decode(MastodonPushNotification.self, from: plaintext) {
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification] present", ((#file as NSString).lastPathComponent), #line, #function)

        }
        completionHandler(.banner)
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: [Push Notification]", ((#file as NSString).lastPathComponent), #line, #function)
        
    }
}

extension AppContext {
    static var shared: AppContext {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.appContext
    }
}
