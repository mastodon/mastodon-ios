// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public class FeedNxt: Equatable {
    public enum Kind: String, CaseIterable, Hashable {
        case none
        case home
        case notificationAll
        case notificationMentions
    }
    
    public let kind: Kind
    public let notification: NotificationNxt?
    
    init(kind: Kind, notification: NotificationNxt?) {
        self.kind = kind
        self.notification = notification
    }
    
    public static func == (lhs: FeedNxt, rhs: FeedNxt) -> Bool {
        lhs.kind == rhs.kind && lhs.notification == rhs.notification
    }
}

public extension FeedNxt {
    static func from(notification: Mastodon.Entity.Notification, as kind: Kind) -> FeedNxt {
        FeedNxt(kind: kind, notification: .from(notification: notification))
    }
}
