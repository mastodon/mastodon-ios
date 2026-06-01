// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public extension UserDefaults {

    enum Keys {
        static let didMigratePushNotificationsKey = "didMigratePushNotifications"
    }
    
    @objc dynamic var didMigratePushNotifications: Bool {
        get {
            return bool(forKey: Keys.didMigratePushNotificationsKey)
        }
        set {
            set(newValue, forKey: Keys.didMigratePushNotificationsKey)
        }
    }
}
