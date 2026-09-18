// Copyright © 2025 Mastodon gGmbH. All rights reserved.

enum PostAction {
    case reply
    case boost
    case favourite
    case bookmark
    
    func systemIconName(filled: Bool) -> String {
        switch self {
        case .reply:
            return "arrow.turn.up.left"
        case .boost:
            return "arrow.2.squarepath"
        case .favourite:
            return filled ? "heart.fill" : "heart"
        case .bookmark:
            return filled ? "bookmark.fill" : "bookmark"
        }
    }
}
