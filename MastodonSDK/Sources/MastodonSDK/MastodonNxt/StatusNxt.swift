// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public class StatusNxt: Hashable {
    public let id: String
    public let reblog: StatusNxt?
    public let author: MastodonUserNxt
    public let createdAt: Date
    
    init(id: String, reblog: StatusNxt?, author: MastodonUserNxt, createdAt: Date) {
        self.id = id
        self.reblog = reblog
        self.author = author
        self.createdAt = createdAt
    }
    
    public static func == (lhs: StatusNxt, rhs: StatusNxt) -> Bool {
        lhs.id == rhs.id && lhs.author.id == rhs.author.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(createdAt)
    }
}

public extension StatusNxt {
    static func from(status: Mastodon.Entity.Status) -> StatusNxt {
        StatusNxt(
            id: status.id,
            reblog: status.reblog != nil ? .from(status: status.reblog!) : nil,
            author: .from(account: status.account),
            createdAt: status.createdAt
        )
    }
    
    static func from(status: Status) -> StatusNxt {
        StatusNxt(
            id: status.id,
            reblog: status.reblog != nil ? .from(status: status.reblog!) : nil,
            author: .from(user: status.author),
            createdAt: status.createdAt
        )
    }
}
