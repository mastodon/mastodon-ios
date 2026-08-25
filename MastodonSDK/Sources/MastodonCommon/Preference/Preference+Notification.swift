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
    
    public func summedNotificationCount() -> Int {
        let prefix = UserDefaults.notificationCountKeyPrefix + "@"
        return dictionaryRepresentation().keys
            .filter({ $0.hasPrefix(prefix) })
            .reduce(0, { previousResult, nextKey in previousResult + integer(forKey: nextKey) })
    }
    
    public func setNotificationCount(_ value: Int, rawAccessToken: String) {
        let prefix = UserDefaults.notificationCountKeyPrefix
        let key = UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: prefix)
        setValue(value, forKey: key)
    }
    
    public func pruneNotificationCounts(keepingRawAccessTokens survivingTokens: [String]) {
        let prefix = UserDefaults.notificationCountKeyPrefix
        let keysToKeep = Set(survivingTokens.map { UserDefaults.deriveKey(fromRawAccessToken: $0, prefix: prefix)})
        let countPrefix = prefix + "@"
        let legacyNotificationsTabPrefix = "last_notification_tab_index@" // this preference was removed in 2026.08
        for key in dictionaryRepresentation().keys {
            if key.hasPrefix(legacyNotificationsTabPrefix) {
                removeObject(forKey: key)
            } else if key.hasPrefix(countPrefix), !keysToKeep.contains(key) {
                removeObject(forKey: key)
            }
        }
    }
    
    public func removeNotificationCount(forRawAccessToken rawAccessToken: String) {
        let key = UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: UserDefaults.notificationCountKeyPrefix)
        removeObject(forKey: key)
    }
}
