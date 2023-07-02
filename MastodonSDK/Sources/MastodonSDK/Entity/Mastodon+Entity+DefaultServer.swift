// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {
    public struct DefaultServer: Codable {
        public let domain: String
        public let weight: Int

        public init(domain: String, weight: Int) {
            self.domain = domain
            self.weight = weight
        }
    }
}
