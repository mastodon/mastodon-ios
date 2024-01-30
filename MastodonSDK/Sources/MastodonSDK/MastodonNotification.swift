// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public final class MastodonNotification {
    public let entity: Mastodon.Entity.Notification
    
    public var id: Mastodon.Entity.Notification.ID {
        entity.id
    }
    
    public let account: Mastodon.Entity.Account
    public var relationship: Mastodon.Entity.Relationship?
    public let status: MastodonStatus?
    public let feeds: [MastodonFeed]
    
    public var followRequestState: MastodonFollowRequestState = .init(state: .none)
    public var transientFollowRequestState: MastodonFollowRequestState = .init(state: .none)
    
    public init(entity: Mastodon.Entity.Notification, account: Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?, status: MastodonStatus?, feeds: [MastodonFeed]) {
        self.entity = entity
        self.account = account
        self.relationship = relationship
        self.status = status
        self.feeds = feeds
    }
}

public extension MastodonNotification {
    static func fromEntity(_ entity: Mastodon.Entity.Notification, relationship: Mastodon.Entity.Relationship?) -> MastodonNotification {
        return MastodonNotification(entity: entity, account: entity.account, relationship: relationship, status: entity.status.map(MastodonStatus.fromEntity), feeds: [])
    }
}

extension MastodonNotification: Hashable {
    public static func == (lhs: MastodonNotification, rhs: MastodonNotification) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
