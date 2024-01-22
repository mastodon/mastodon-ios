// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public final class MastodonNotification {
    public let entity: Mastodon.Entity.Notification
    
    public var id: Mastodon.Entity.Notification.ID {
        entity.id
    }
    
    public let account: MastodonUser
    public let status: MastodonStatus?
    public let feeds: [MastodonFeed]
    
    public var followRequestState: MastodonFollowRequestState = .init(state: .none)
    public var transientFollowRequestState: MastodonFollowRequestState = .init(state: .none)
    
    public init(entity: Mastodon.Entity.Notification, account: MastodonUser, status: MastodonStatus?, feeds: [MastodonFeed]) {
        self.entity = entity
        self.account = account
        self.status = status
        self.feeds = feeds
    }
}

public extension MastodonNotification {
    static func fromEntity(_ entity: Mastodon.Entity.Notification, using managedObjectContext: NSManagedObjectContext, domain: String) -> MastodonNotification? {
        guard let user = MastodonUser.fetch(in: managedObjectContext, configurationBlock: { request in
            request.predicate = MastodonUser.predicate(domain: domain, id: entity.account.id)
        }).first else {
            assertionFailure()
            return nil
        }
        return MastodonNotification(entity: entity, account: user, status: entity.status.map(MastodonStatus.fromEntity), feeds: [])
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
