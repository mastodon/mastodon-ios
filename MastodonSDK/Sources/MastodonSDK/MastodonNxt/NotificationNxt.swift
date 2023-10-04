// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

public class NotificationNxt: Hashable {
    public let id: String
    public let status: StatusNxt?
    public let account: MastodonUserNxt
    public let typeRaw: String
    
    init(id: String, status: StatusNxt?, account: MastodonUserNxt, typeRaw: String) {
        self.id = id
        self.status = status
        self.account = account
        self.typeRaw = typeRaw
    }
    
    public static func == (lhs: NotificationNxt, rhs: NotificationNxt) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

public extension NotificationNxt {
    static func from(notification: Mastodon.Entity.Notification) -> NotificationNxt {
        NotificationNxt(
            id: notification.id,
            status: notification.status != nil ? StatusNxt.from(status: notification.status!) : nil,
            account: MastodonUserNxt.from(account: notification.account),
            typeRaw: notification.type.rawValue
        )
    }
}
