// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public extension FileManager {
    var documentsDirectory: URL? {
        urls(for: .documentDirectory, in: .userDomainMask).first
    }

    var cachesDirectory: URL? {
        urls(for: .cachesDirectory, in: .userDomainMask).first
    }
}
