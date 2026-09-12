// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Foundation
import AppIntents
import MastodonSDK

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum PostVisibilityAppEnum: String, AppEnum {
    // App Intents persists these by raw string, so `public` and `followersOnly`
    // must keep their names for shortcuts migrated from the legacy intent.
    // Appending new cases is safe.
    case `public`
    case unlisted
    case followersOnly
    case direct

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Post Visibility")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .public: "Public",
        .unlisted: "Quiet public",
        .followersOnly: "Followers Only",
        .direct: "Private mention"
    ]

    var statusVisibility: Mastodon.Entity.Status.Visibility {
        switch self {
        case .public:        return .public
        case .unlisted:      return .unlisted
        case .followersOnly: return .private
        case .direct:        return .direct
        }
    }
}

