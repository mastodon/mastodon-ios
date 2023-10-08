// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {
    /// Extended description of the server

    /// ## Reference:
    /// [Document](https://docs.joinmastodon.org/entities/ExtendedDescription/)
    public struct ExtendedDescription: Codable {
        let updatedAt: Date
        let content: String

        enum CodingKeys: String, CodingKey {
            case updatedAt = "updated_at"
            case content
        }
    }
}
