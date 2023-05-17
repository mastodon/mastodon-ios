// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {
    public struct StatusSource: Codable {
        public let id: String
        public let text: String
        public let spoilerText: String

        enum CodingKeys: String, CodingKey {
            case id
            case text
            case spoilerText = "spoiler_text"
        }
    }
}
