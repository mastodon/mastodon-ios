// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack
import MastodonSDK
import MastodonCore

public protocol StatusCompatible {
    var reblog: Mastodon.Entity.Status? { get }
    var attachments: [MastodonAttachment] { get }
    var isMediaSensitive: Bool { get }
    var isSensitiveToggled: Bool { get }
}

extension MastodonStatusEntity: StatusCompatible{
    public var attachments: [MastodonAttachment] {
        status.mastodonAttachments
    }
    
    public var isMediaSensitive: Bool {
        status.sensitive == true
    }

    public var reblog: Mastodon.Entity.Status? {
        status.reblog
    }
}
