//
//  UserDefaults+Notification.swift
//  MastodonCommon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import UIKit
import CryptoKit
import MastodonExtension

extension UserDefaults {
    // always use hash value (SHA256) from accessToken as key
    private static func deriveKey(fromRawAccessToken accessToken: String, prefix: String) -> String {
        let digest = SHA256.hash(data: Data(accessToken.utf8))
        let bytes = [UInt8](digest)
        let hex = bytes.toHexString()
        let key = prefix + "@" + hex
        return key
    }
    
    private static let notificationCountKeyPrefix = "notification_count"
    private static let notificationsLastTabIndexKeyPrefix = "last_notification_tab_index"

    public func notificationCount(rawAccessToken: String) -> Int {
        let prefix = UserDefaults.notificationCountKeyPrefix
        let key = UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: prefix)
        return integer(forKey: key)
    }
    
    public func incrementNotificationCount(rawAccessToken: String) {
        let prefix = UserDefaults.notificationCountKeyPrefix
        let key = UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: prefix)
        let currentCount = notificationCount(rawAccessToken: rawAccessToken)
        setValue(currentCount + 1, forKey: key)
    }
    
    public func setNotificationCount(_ value: Int, rawAccessToken: String) {
        let prefix = UserDefaults.notificationCountKeyPrefix
        let key = UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: prefix)
        setValue(value, forKey: key)
    }

    @objc public func getLastSelectedNotificationsTabName(accessToken: String) -> String? {
        let prefix = UserDefaults.notificationsLastTabIndexKeyPrefix
        let key = UserDefaults.deriveKey(fromRawAccessToken: accessToken, prefix: prefix)
        return object(forKey: key) as? String
    }
    
    @objc public func setLastSelectedNotificationsTabName(accessToken: String, value: String?) {
        let prefix = UserDefaults.notificationsLastTabIndexKeyPrefix
        let key = UserDefaults.deriveKey(fromRawAccessToken: accessToken, prefix: prefix)
        setValue(value, forKey: key)
    }
}

extension UserDefaults {
    
    @objc public dynamic var notificationBadgeCount: Int {
        get {
            register(defaults: [#function: 0])
            return integer(forKey: #function)
        }
        set { self[#function] = newValue }
    }

}
