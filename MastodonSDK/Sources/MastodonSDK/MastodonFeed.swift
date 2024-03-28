// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public final class MastodonFeed {
    
    public enum Kind {

        case home(timeline: HomeTimeline)
        case notificationAll
        case notificationMentions

        public enum HomeTimeline {
            case following
            case localCommunity
        }
    }
    
    public let id: String
    public var hasMore: Bool = false
    public var isLoadingMore: Bool = false
    
    public let status: MastodonStatus?
    public let relationship: Mastodon.Entity.Relationship?
    public let notification: Mastodon.Entity.Notification?
    
    public let kind: Feed.Kind
    
    init(hasMore: Bool, isLoadingMore: Bool, status: MastodonStatus?, notification: Mastodon.Entity.Notification?, relationship: Mastodon.Entity.Relationship?, kind: Feed.Kind) {
        self.id = notification?.id ?? status?.id ?? UUID().uuidString
        self.hasMore = hasMore
        self.isLoadingMore = isLoadingMore
        self.status = status
        self.notification = notification
        self.relationship = relationship
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
            relationship: nil,
            kind: kind
        )
    }
    
    static func fromNotification(_ notification: Mastodon.Entity.Notification, relationship: Mastodon.Entity.Relationship?, kind: Feed.Kind) -> MastodonFeed {
        MastodonFeed(
            hasMore: false,
            isLoadingMore: false,
            status: {
                guard let status = notification.status else {
                    return nil
                }
                return .fromEntity(status)
            }(),
            notification: notification,
            relationship: relationship,
            kind: kind
        )
    }
}

extension MastodonFeed: Hashable {
    public static func == (lhs: MastodonFeed, rhs: MastodonFeed) -> Bool {
        lhs.id == rhs.id && 
        lhs.status?.entity == rhs.status?.entity &&
        lhs.status?.reblog?.entity == rhs.status?.reblog?.entity &&
        lhs.status?.isSensitiveToggled == rhs.status?.isSensitiveToggled &&
        lhs.status?.reblog?.isSensitiveToggled == rhs.status?.reblog?.isSensitiveToggled
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(status?.entity)
        hasher.combine(status?.reblog?.entity)
        hasher.combine(status?.isSensitiveToggled)
        hasher.combine(status?.reblog?.isSensitiveToggled)
    }
    
}
