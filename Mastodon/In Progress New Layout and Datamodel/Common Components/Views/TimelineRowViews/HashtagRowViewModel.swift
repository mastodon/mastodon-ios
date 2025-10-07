// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonSDK

@MainActor
@Observable class HashtagRowViewModel: FeedCoordinatorUpdatable {
    
    private(set) var entity: Mastodon.Entity.Tag
    let id: String
    
    init(entity: Mastodon.Entity.Tag) {
        self.entity = entity
        id = entity.uniqueID
    }
    
    func incorporateUpdate(_ update: UpdatedElement) {
        switch update {
        case .hashtag(let updated):
            guard updated.uniqueID == id else { return }
            self.entity = updated
        case .post, .deletedPost, .relationship:
            break
        }
    }
}

extension Mastodon.Entity.Tag {
    var uniqueID: String {
        return name + "-" + url
    }
}
