// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Combine
import MastodonUI
import CoreDataStack

extension SuggestionAccountTableViewCell {
    final class ViewModel {
        let user: MastodonUser

        let followedUsers: [String]
        let blockedUsers: [String]
        let followRequestedUsers: [String]

        init(user: MastodonUser, followedUsers: [String], blockedUsers: [String], followRequestedUsers: [String]) {
            self.user = user
            self.followedUsers = followedUsers
            self.followRequestedUsers = followRequestedUsers
            self.blockedUsers =  blockedUsers
        }
    }
}
