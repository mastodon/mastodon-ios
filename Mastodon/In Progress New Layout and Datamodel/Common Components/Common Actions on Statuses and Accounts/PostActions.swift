// Copyright © 2025 Mastodon gGmbH. All rights reserved.

import SwiftUI
import MastodonAsset

enum PostAction {
    case reply
    case boost
    case favourite
    case bookmark
    
    func icon(filled: Bool) -> Image {
        switch self {
        case .reply:
            Image(phosphor: .chatCircle) // no filled variant
        case .boost:
            Image(phosphor: .arrowsClockwise, filled: filled)
        case .favourite:
            Image(phosphor: .heart, filled: filled)
        case .bookmark:
            Image(phosphor: .bookmarkSimple, filled: filled)
        }
    }
}
