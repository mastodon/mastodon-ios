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
    private static let lastSuccessfulAccountFetchPrefix = "last_successful_account_fetch"
    
    public func lastSuccessfulAccountFetch(forRawAccessToken rawAccessToken: String) -> Date? {
        let key = UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: UserDefaults.lastSuccessfulAccountFetchPrefix)
        return object(forKey: key) as? Date
    }
    
    public func setLastSuccessfulAccountFetch(forRawAccessToken rawAccessToken: String) {
        let key = UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: UserDefaults.lastSuccessfulAccountFetchPrefix)
        set(Date.now, forKey: key)
    }

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
    
    public func prunePerAccountKeys(keepingRawAccessTokens survivingTokens: [String]) {
        let keysToKeep = Set(survivingTokens.flatMap {
            [ UserDefaults.deriveKey(fromRawAccessToken: $0, prefix: UserDefaults.notificationCountKeyPrefix),
                UserDefaults.deriveKey(fromRawAccessToken: $0, prefix: UserDefaults.lastSuccessfulAccountFetchPrefix) ]
        })
        let countPrefix = UserDefaults.notificationCountKeyPrefix + "@"
        let lastFetchPrefix = UserDefaults.lastSuccessfulAccountFetchPrefix + "@"
        let legacyNotificationsTabPrefix = "last_notification_tab_index@" // this preference was removed in 2026.08
        for key in dictionaryRepresentation().keys {
            if key.hasPrefix(legacyNotificationsTabPrefix) {
                removeObject(forKey: key)
            } else if (key.hasPrefix(countPrefix) || key.hasPrefix(lastFetchPrefix)), !keysToKeep.contains(key) {
                removeObject(forKey: key)
            }
        }
    }
    
    public func removeAccountKeys(forRawAccessToken rawAccessToken: String) {
        let keys = [
            UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: UserDefaults.notificationCountKeyPrefix),
            UserDefaults.deriveKey(fromRawAccessToken: rawAccessToken, prefix: UserDefaults.lastSuccessfulAccountFetchPrefix)
        ]
        for key in keys {
            removeObject(forKey: key)
        }
    }
}
