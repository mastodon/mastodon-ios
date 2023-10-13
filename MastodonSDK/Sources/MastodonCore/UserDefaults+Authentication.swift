// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public extension UserDefaults {

    enum Keys {
        static let didMigrateAuthenticationsKey = "didMigrateAuthentications"
    }

    @objc dynamic var didMigrateAuthentications: Bool {
        get {
            return bool(forKey: Keys.didMigrateAuthenticationsKey)
        }

        set {
            set(newValue, forKey: Keys.didMigrateAuthenticationsKey)
        }
    }
}
