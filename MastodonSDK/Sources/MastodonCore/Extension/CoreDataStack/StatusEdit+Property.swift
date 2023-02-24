// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack
import MastodonSDK

extension StatusEdit.Property {
    init(entity: Mastodon.Entity.StatusEdit) {
        self.init(
            createdAt: entity.createdAt,
            content: entity.content,
            sensitive: entity.sensitive,
            spoilerText: entity.spoilerText,
            emojis: entity.mastodonEmojis,
            attachments: entity.mastodonAttachments)
    }
}

extension Mastodon.Entity.StatusEdit {
    public var mastodonAttachments: [MastodonAttachment] {
        mediaAttachments.mastodonAttachments
    }
}
