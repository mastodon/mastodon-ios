// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {
    public struct NotificationRequest: Codable, Hashable {
        public let id: String
        public let createdAt: Date
        public let updatedAt: Date
        public let fromAccount: Mastodon.Entity.Account
        public let notificationsCount: Int
        public let lastStatus: Mastodon.Entity.Status?

        enum CodingKeys: String, CodingKey {
            case id = "id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case fromAccount = "from_account"
            case notificationsCount = "notifications_count"
            case lastStatus = "last_status"
        }
    }
}
