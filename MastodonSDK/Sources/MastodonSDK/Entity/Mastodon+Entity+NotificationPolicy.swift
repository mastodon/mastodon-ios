// Copyright © 2024 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {
    public struct NotificationPolicy: Codable {
        let filterNotFollowing: Bool
        let filterNotFollowers: Bool
        let filterNewAccounts: Bool
        let filterPrivateMentions: Bool
        let summary: Summary

        enum CodingKeys: String, CodingKey {
            case filterNotFollowing = "filter_not_following"
            case filterNotFollowers = "filter_not_followers"
            case filterNewAccounts = "filter_new_accounts"
            case filterPrivateMentions = "filter_private_mentions"
            case summary
        }

        public struct Summary: Codable {
            let pendingRequestsCount: Int
            let pendingNotificationsCount: Int

            enum CodingKeys: String, CodingKey {
                case pendingRequestsCount = "pending_requests_count"
                case pendingNotificationsCount = "pending_notifications_count"
            }
        }
    }
}
