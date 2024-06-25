// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {
    public struct NotificationPolicy: Codable, Hashable {
        public let filterNotFollowing: Bool
        public let filterNotFollowers: Bool
        public let filterNewAccounts: Bool
        public let filterPrivateMentions: Bool
        public let summary: Summary

        enum CodingKeys: String, CodingKey {
            case filterNotFollowing = "filter_not_following"
            case filterNotFollowers = "filter_not_followers"
            case filterNewAccounts = "filter_new_accounts"
            case filterPrivateMentions = "filter_private_mentions"
            case summary
        }

        public struct Summary: Codable, Hashable {
            public let pendingRequestsCount: Int
            public let pendingNotificationsCount: Int

            enum CodingKeys: String, CodingKey {
                case pendingRequestsCount = "pending_requests_count"
                case pendingNotificationsCount = "pending_notifications_count"
            }
        }
    }
}
