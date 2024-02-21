//
//  Mastodon+Entity+Account.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import Foundation
import MastodonSDK
import MastodonMeta

extension Mastodon.Entity.Account {
    public var emojiMeta: MastodonContent.Emojis {
        let isAnimated = !UserDefaults.shared.preferredStaticEmoji

        var dict = MastodonContent.Emojis()
        for emoji in emojis {
            dict[emoji.shortcode] = isAnimated ? emoji.url : emoji.staticURL
        }
        return dict
    }
}
