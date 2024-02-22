//
//  MastodonEmojiContainer.swift
//  MastodonEmojiContainer
//
//  Created by Cirno MainasuK on 2021-9-3.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import MastodonSDK
import CoreDataStack

public protocol MastodonEmojiContainer {
    var emojis: [Mastodon.Entity.Emoji] { get }
}

extension MastodonEmojiContainer {
    public var mastodonEmojis: [MastodonEmoji] {
        return emojis.map { MastodonEmoji(emoji: $0) }
    }
}

extension Mastodon.Entity.Account: MastodonEmojiContainer { }
extension Mastodon.Entity.Status: MastodonEmojiContainer { }
extension Mastodon.Entity.StatusEdit: MastodonEmojiContainer { }
