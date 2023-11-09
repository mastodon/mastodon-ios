// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

extension Mastodon.Entity.StatusEdit: Hashable, Equatable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(content)
    }
    
    public static func == (lhs: Mastodon.Entity.StatusEdit, rhs: Mastodon.Entity.StatusEdit) -> Bool {
        lhs.createdAt == rhs.createdAt && lhs.content == rhs.content
    }
}
