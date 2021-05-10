//
//  Emojis.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-7.
//

import Foundation
import MastodonSDK

protocol EmojiContinaer {
    var emojisData: Data? { get }
}

extension EmojiContinaer {
    
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
    
}

