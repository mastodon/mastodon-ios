// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

extension AttributeContainer {
    public init<T>(_ attribute: WritableKeyPath<AttributeContainer, T>, value: T) {
        self.init()
        self[keyPath: attribute] = value
    }

    public init<T>(_ attribute: WritableKeyPath<AttributeContainer, T>, value: T?) {
        self.init()
        if let value {
            self[keyPath: attribute] = value
        }
    }
}
