// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Combine
import MastodonUI
import MastodonSDK

extension SuggestionAccountTableViewCell {
    final class ViewModel {
        let user: Mastodon.Entity.Account

        let followedUsers: [String]
        let blockedUsers: [String]
        let followRequestedUsers: [String]

        init(user: Mastodon.Entity.Account, followedUsers: [String], blockedUsers: [String], followRequestedUsers: [String]) {
            self.user = user
            self.followedUsers = followedUsers
            self.followRequestedUsers = followRequestedUsers
            self.blockedUsers =  blockedUsers
        }
    }
}
