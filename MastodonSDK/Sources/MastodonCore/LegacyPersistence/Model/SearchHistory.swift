// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

extension Persistence.SearchHistory {
    public struct Item: Codable, Hashable, Equatable {
        public let updatedAt: Date
        public let userID: Mastodon.Entity.Account.ID

        public let account: Mastodon.Entity.Account?
        public let hashtag: Mastodon.Entity.Tag?

        public init(updatedAt: Date, userID: Mastodon.Entity.Account.ID, account: Mastodon.Entity.Account?, hashtag: Mastodon.Entity.Tag?) {
            self.updatedAt = updatedAt
            self.userID = userID
            self.account = account
            self.hashtag = hashtag
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(userID)
            hasher.combine(account)
            hasher.combine(hashtag)
        }

        public static func == (lhs: Persistence.SearchHistory.Item, rhs: Persistence.SearchHistory.Item) -> Bool {
            return lhs.account == rhs.account && lhs.hashtag == rhs.hashtag && lhs.userID == rhs.userID
        }
    }
}
