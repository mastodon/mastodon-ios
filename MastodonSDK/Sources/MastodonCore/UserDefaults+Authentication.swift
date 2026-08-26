// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public extension UserDefaults {
    var didMigratePushNotifications: Bool {
        get { return bool(forKey: #function) }
        set { self[#function] = newValue }
    }
}
