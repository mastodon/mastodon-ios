//
//  Emojis.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-7.
//

import Foundation
import MastodonSDK
import MastodonMeta

protocol EmojiContainer {
    var emojisData: Data? { get }
}

// FIXME: `Mastodon.Entity.Account` extension

extension EmojiContainer {
    
    static func encode(emojis: [Mastodon.Entity.Emoji]) -> Data? {
        return try? JSONEncoder().encode(emojis)
    }

    var emojis: [Mastodon.Entity.Emoji]? {
        let decoder = JSONDecoder()
        return emojisData.flatMap { try? decoder.decode([Mastodon.Entity.Emoji].self, from: $0) }
    }

    var emojiMeta: MastodonContent.Emojis {
        let isAnimated = !UserDefaults.shared.preferredStaticEmoji

        var dict = MastodonContent.Emojis()
        for emoji in emojis ?? [] {
            dict[emoji.shortcode] = isAnimated ? emoji.url : emoji.staticURL
        }
        return dict
    }
    
}

