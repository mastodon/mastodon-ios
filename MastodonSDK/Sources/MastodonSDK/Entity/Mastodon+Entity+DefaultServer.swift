// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {
    public struct DefaultServer: Codable {
        let domain: String
        let weight: Int
    }
}
