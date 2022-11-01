//
//  MastodonEmoji.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import Foundation
import CoreDataStack
import MastodonMeta
import MastodonSDK

extension Collection where Element == MastodonEmoji {
    public var asDictionary: MastodonContent.Emojis {
        var dictionary: MastodonContent.Emojis = [:]
        for emoji in self {
            dictionary[emoji.code] = emoji.url
        }
        return dictionary
    }
}

extension Collection where Element == Mastodon.Entity.Emoji {
    public var asDictionary: MastodonContent.Emojis {
        var dictionary: MastodonContent.Emojis = [:]
        for emoji in self {
            dictionary[emoji.shortcode] = emoji.url
        }
        return dictionary
    }
}

extension MastodonEmoji {
    public convenience init(emoji: Mastodon.Entity.Emoji) {
        self.init(
            code: emoji.shortcode,
            url: emoji.url,
            staticURL: emoji.staticURL,
            visibleInPicker: emoji.visibleInPicker,
            category: emoji.category
        )
    }
}
