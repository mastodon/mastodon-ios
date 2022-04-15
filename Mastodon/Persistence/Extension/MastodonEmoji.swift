//
//  MastodonEmojis.swift
//  MastodonEmojis
//
//  Created by Cirno MainasuK on 2021-9-2.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreDataStack
import MastodonSDK
import MastodonMeta

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
