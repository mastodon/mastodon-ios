// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public class MastodonUserNxt: ObservableObject, Hashable {
    public let id: String
    
    init(id: String) {
        self.id = id
    }
    
    public static func == (lhs: MastodonUserNxt, rhs: MastodonUserNxt) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension MastodonUserNxt {
    static func from(account: Mastodon.Entity.Account) -> MastodonUserNxt {
        MastodonUserNxt(id: account.id)
    }
}

public extension MastodonUserNxt {
    static func from(user: MastodonUser) -> MastodonUserNxt {
        MastodonUserNxt(id: user.id)
    }
}
