// Copyright © 2026 Mastodon gGmbH. All rights reserved.

import Foundation
import MastodonSDK

#if DEBUG

private let basicStatusJSON = """
    {
      "id": "110000000000000001",
      "uri": "https://mastodon.social/users/testodon/statuses/110000000000000001",
      "url": "https://mastodon.social/@testodon/110000000000000001",
      "created_at": "\(ISO8601DateFormatter().string(from: .now))",
      "content": "<p>This is a basic post.</p>",
      "visibility": "public",
      "sensitive": false,
      "spoiler_text": "",
      "mentions": [],
      "tags": [],
      "emojis": [],
      "reblogs_count": 0,
      "favourites_count": 0,
      "replies_count": 0,
      "account": {
        "id": "1",
        "username": "testodon",
        "acct": "testodon@mastodon.social",
        "url": "https://mastodon.social/@testodon",
        "display_name": "Testodon",
        "note": "",
        "avatar": "",
        "header": "",
        "locked": false,
        "emojis": [],
        "created_at": "2026-01-01T00:00:00Z",
        "statuses_count": 0,
        "followers_count": 0,
        "following_count": 0
      }
    }
    """

enum PostPreviewModel {
    case basicPost
    
    @MainActor
    func postViewModel() -> MastodonPostViewModel {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        switch self {
        case .basicPost:
            do {
                let status = try decoder.decode(Mastodon.Entity.Status.self, from: Data(basicStatusJSON.utf8))
                let post = GenericMastodonPost.fromStatus(status, authenticatedDomain: "mastodon.social")
                let viewModel = MastodonPostViewModel(post.initialDisplayInfo(), displayType: .standard)
                viewModel.initialSetFullPost(post)
                return viewModel
            } catch {
                fatalError("failed to decode previewPost: \(error)")
            }
        }
    }
}

#endif
