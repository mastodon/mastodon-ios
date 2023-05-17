// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Accessibility

extension AXCustomContent {
    convenience init?(label: String, value: String?) {
        if let value, !value.isEmpty {
            self.init(label: label, value: value)
        } else {
            return nil
        }
    }

    convenience init?(label: String, value: (some BinaryInteger)?) {
        if let value {
            self.init(label: label, value: value.formatted())
        } else {
            return nil
        }
    }
}
