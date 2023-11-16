// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public struct FeedItem: Hashable {
    public static func == (lhs: FeedItem, rhs: FeedItem) -> Bool {
        lhs.status == rhs.status && lhs.notification == rhs.notification
    }
    
    public let status: Mastodon.Entity.Status?
    public let notification: Mastodon.Entity.Notification?
    public let hasMore: Bool
    public let isLoadingMore: Bool
    
    public init(status: Mastodon.Entity.Status?, notification: Mastodon.Entity.Notification?, hasMore: Bool, isLoadingMore: Bool) {
        self.status = status
        self.notification = notification
        self.hasMore = hasMore
        self.isLoadingMore = isLoadingMore
    }
}
