// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

@MainActor
@Observable class HashtagRowViewModel {
    
    var entity: Mastodon.Entity.Tag
    let id: String
    
    init(entity: Mastodon.Entity.Tag) {
        self.entity = entity
        id = entity.uniqueID
    }
}

extension Mastodon.Entity.Tag {
    var uniqueID: String {
        return name + "-" + url
    }
}
