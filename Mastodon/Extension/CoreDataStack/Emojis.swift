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

extension EmojiContainer {
    
    static func encode(emojis: [Mastodon.Entity.Emoji]) -> Data? {
        return try? JSONEncoder().encode(emojis)
    }

    var emojis: [Mastodon.Entity.Emoji]? {
        let decoder = JSONDecoder()
        return emojisData.flatMap { try? decoder.decode([Mastodon.Entity.Emoji].self, from: $0) }
    }
    
    var emojiDict: MastodonStatusContent.EmojiDict {
        var dict = MastodonStatusContent.EmojiDict()
        for emoji in emojis ?? [] {
            guard let url = URL(string: emoji.url) else { continue }
            dict[emoji.shortcode] = url
        }
        return dict
    }

    var emojiMeta: MastodonContent.Emojis {
        var dict = MastodonContent.Emojis()
        for emoji in emojis ?? [] {
            dict[emoji.shortcode] = emoji.url
        }
        return dict
    }
    
}

