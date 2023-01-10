// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation

extension Mastodon.Entity {

    /// StatusEdit
    ///
    /// - Since: 0.1.0
    /// - Version: 3.5.0
    /// # Last Update
    ///   2022/12/14
    /// # Reference
    ///  [Document](https://docs.joinmastodon.org/entities/statusedit/)
    public class StatusEdit: Codable {
        public let content: String
        public let spoilerText: String?
        public let sensitive: Bool
        public let createdAt: Date
        public let account: Account
        public let poll: Poll?
        public let mediaAttachments: [Attachment]?
        public let emojis: [Emoji]?

        enum CodingKeys: String, CodingKey {
            case content
            case spoilerText = "spoiler_text"
            case sensitive
            case createdAt = "created_at"
            case account
            case poll
            case mediaAttachments = "media_attachments"
            case emojis
        }
    }
}
