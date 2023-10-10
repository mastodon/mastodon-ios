// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

public struct StatusCompatible {
    let reblog: Mastodon.Entity.Status?
    let mediaAttachments: [Mastodon.Entity.Attachment]?
    let isMediaSensitive: Bool
    var isSensitiveToggled: Bool
    
    static func from(status: Mastodon.Entity.Status) -> Self {
        return StatusCompatible(
            reblog: status.reblog,
            mediaAttachments: status.mediaAttachments,
            isMediaSensitive: status.sensitive ?? false,
            isSensitiveToggled: false
        )
    }
    
    static func from(statusEdit: Mastodon.Entity.StatusEdit) -> Self {
        return StatusCompatible(
            reblog: nil,
            mediaAttachments: statusEdit.mediaAttachments,
            isMediaSensitive: statusEdit.sensitive,
            isSensitiveToggled: true
        )
    }
    
    func toggleSensitive(_ on: Bool) -> Self {
        return StatusCompatible(
            reblog: reblog,
            mediaAttachments: mediaAttachments,
            isMediaSensitive: isMediaSensitive,
            isSensitiveToggled: on
        )
    }
}
