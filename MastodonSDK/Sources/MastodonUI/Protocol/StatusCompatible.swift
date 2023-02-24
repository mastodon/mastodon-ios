// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreDataStack

public protocol StatusCompatible {
    var reblog: Status? { get }
    var attachments: [MastodonAttachment] { get }
    var isMediaSensitive: Bool { get }
    var isSensitiveToggled: Bool { get }
}

extension Status: StatusCompatible {}

extension StatusEdit: StatusCompatible {
    public var reblog: Status? {
        nil
    }
    
    public var isMediaSensitive: Bool {
        sensitive
    }
    
    public var isSensitiveToggled: Bool {
        true
    }
}
