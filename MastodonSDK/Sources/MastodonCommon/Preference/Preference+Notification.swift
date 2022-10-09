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
    private static func deriveKey(from accessToken: String, prefix: String) -> String {
        let digest = SHA256.hash(data: Data(accessToken.utf8))
        let bytes = [UInt8](digest)
        let hex = bytes.toHexString()
        let key = prefix + "@" + hex
        return key
    }
    
    private static let notificationCountKeyPrefix = "notification_count"
    
    public func getNotificationCountWithAccessToken(accessToken: String) -> Int {
        let prefix = UserDefaults.notificationCountKeyPrefix
        let key = UserDefaults.deriveKey(from: accessToken, prefix: prefix)
        return integer(forKey: key)
    }
    
    public func setNotificationCountWithAccessToken(accessToken: String, value: Int) {
        let prefix = UserDefaults.notificationCountKeyPrefix
        let key = UserDefaults.deriveKey(from: accessToken, prefix: prefix)
        setValue(value, forKey: key)
    }
    
    public func increaseNotificationCount(accessToken: String) {
        let count = getNotificationCountWithAccessToken(accessToken: accessToken)
        setNotificationCountWithAccessToken(accessToken: accessToken, value: count + 1)
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
