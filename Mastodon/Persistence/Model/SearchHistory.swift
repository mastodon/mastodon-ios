// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

extension Persistence.SearchHistory {
    struct Item: Codable, Hashable, Equatable {
        let updatedAt: Date
        let userID: Mastodon.Entity.Account.ID

        let account: Mastodon.Entity.Account?
        let hashtag: Mastodon.Entity.Tag?

        func hash(into hasher: inout Hasher) {
            hasher.combine(userID)
            hasher.combine(account)
            hasher.combine(hashtag)
        }

        public static func == (lhs: Persistence.SearchHistory.Item, rhs: Persistence.SearchHistory.Item) -> Bool {
            return lhs.account == rhs.account && lhs.hashtag == rhs.hashtag
        }
    }
}
