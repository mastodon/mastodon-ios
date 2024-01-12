// Copyright © 2024 Mastodon gGmbH. All rights reserved.

public protocol StatusesMediaAttachmentsPollsContaining {
    var statuses: Mastodon.Entity.Instance.Configuration.Statuses? { get }
    var mediaAttachments: Mastodon.Entity.Instance.Configuration.MediaAttachments? { get }
    var polls: Mastodon.Entity.Instance.Configuration.Polls? { get }
}
