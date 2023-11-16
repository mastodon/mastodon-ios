// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

public class MastodonStatusEntity: Hashable {
    public static func == (lhs: MastodonStatusEntity, rhs: MastodonStatusEntity) -> Bool {
        lhs.status.id == rhs.status.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(status.id)
    }
    
    public let status: Mastodon.Entity.Status
    public var isSensitiveToggled: Bool = false

    public init(status: Mastodon.Entity.Status) {
        self.status = status
    }
}
