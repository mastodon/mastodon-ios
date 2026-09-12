// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct PostAppEntity: TransientAppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Post")

    @Property(title: "URL")
    var url: URL?

    // Mirrors the display and subtitle the legacy `Post` INObject carried.
    var acct: String = ""
    var content: String = ""

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(acct)", subtitle: "\(content)")
    }

    init() {
    }
}

