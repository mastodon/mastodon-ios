// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonCore
import MastodonSDK

extension Persistence.SearchHistory {
    struct Item: Codable {
        let updatedAt: Date
        let userID: Mastodon.Entity.Account.ID

        let account: Mastodon.Entity.Account?
        let hashtag: Mastodon.Entity.Tag?
    }
}
