// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Combine
import MastodonUI
import CoreDataStack

extension SuggestionAccountTableViewCell {
    final class ViewModel {
        let user: MastodonUser

        let followedUsers: AnyPublisher<[String], Never>
        let blockedUsers: AnyPublisher<[String], Never>
        let followRequestedUsers: AnyPublisher<[String], Never>

        init(user: MastodonUser, followedUsers: AnyPublisher<[String], Never>, blockedUsers: AnyPublisher<[String], Never>, followRequestedUsers: AnyPublisher<[String], Never>) {
            self.user = user
            self.followedUsers = followedUsers
            self.followRequestedUsers = followRequestedUsers
            self.blockedUsers =  blockedUsers
        }
    }
}
