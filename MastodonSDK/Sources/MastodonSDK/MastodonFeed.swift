// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public final class MastodonFeed {
    
    public enum Kind {

        case home(timeline: TimelineContext)
        case notificationAll
        case notificationMentions

        public enum TimelineContext: Equatable {
            case home
            case `public`
            case list(String)
            case hashtag(String)
        }
    }
    
    public let id: String
    
    @Published
    public var hasMore: Bool = false
    
    @Published
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
    static func fromStatus(_ status: MastodonStatus, kind: Feed.Kind, hasMore: Bool? = nil) -> MastodonFeed {
        MastodonFeed(
            hasMore: hasMore ?? false,
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
        lhs.status?.poll == rhs.status?.poll &&
        lhs.status?.reblog?.entity == rhs.status?.reblog?.entity &&
        lhs.status?.reblog?.poll == rhs.status?.reblog?.poll &&
        lhs.status?.isSensitiveToggled == rhs.status?.isSensitiveToggled &&
        lhs.status?.reblog?.isSensitiveToggled == rhs.status?.reblog?.isSensitiveToggled &&
        lhs.status?.poll == rhs.status?.poll &&
        lhs.status?.reblog?.poll == rhs.status?.reblog?.poll &&
        lhs.status?.poll?.entity == rhs.status?.poll?.entity &&
        lhs.status?.reblog?.poll?.entity == rhs.status?.reblog?.poll?.entity &&
        lhs.isLoadingMore == rhs.isLoadingMore
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(status?.entity)
        hasher.combine(status?.poll)
        hasher.combine(status?.reblog?.entity)
        hasher.combine(status?.reblog?.poll)
        hasher.combine(status?.isSensitiveToggled)
        hasher.combine(status?.reblog?.isSensitiveToggled)
        hasher.combine(status?.poll)
        hasher.combine(status?.reblog?.poll)
        hasher.combine(status?.poll?.entity)
        hasher.combine(status?.reblog?.poll?.entity)
        hasher.combine(isLoadingMore)
    }
    
}
