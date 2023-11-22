// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public final class MastodonFeed {
    public var hasMore: Bool = false
    public var isLoadingMore: Bool = false
    
    public let status: MastodonStatus?
    public let notification: Mastodon.Entity.Notification?
    
    public let kind: Feed.Kind
    
    init(hasMore: Bool, isLoadingMore: Bool, status: MastodonStatus?, notification: Mastodon.Entity.Notification?, kind: Feed.Kind) {
        self.hasMore = hasMore
        self.isLoadingMore = isLoadingMore
        self.status = status
        self.notification = notification
        self.kind = kind
    }
}

public extension MastodonFeed {
    static func fromStatus(_ status: MastodonStatus, kind: Feed.Kind) -> MastodonFeed {
        MastodonFeed(
            hasMore: false,
            isLoadingMore: false,
            status: status,
            notification: nil,
            kind: kind
        )
    }
    
    static func fromNotification(_ notification: Mastodon.Entity.Notification, kind: Feed.Kind) -> MastodonFeed {
        MastodonFeed(
            hasMore: false,
            isLoadingMore: false,
            status: nil,
            notification: notification,
            kind: kind
        )
    }
}

extension MastodonFeed: Hashable {
    public static func == (lhs: MastodonFeed, rhs: MastodonFeed) -> Bool {
        lhs.status?.id == rhs.status?.id || lhs.notification?.id == rhs.notification?.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(status)
        hasher.combine(notification)
    }
    
}
