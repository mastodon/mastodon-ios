//
//  MastodonEmoji.swift
//  
//
//  Created by MainasuK on 2022-4-14.
//

import Foundation
import CoreDataStack
import MastodonMeta

extension Collection where Element == MastodonEmoji {
    public var asDictionary: MastodonContent.Emojis {
        var dictionary: MastodonContent.Emojis = [:]
        for emoji in self {
            dictionary[emoji.code] = emoji.url
        }
        return dictionary
    }
}
