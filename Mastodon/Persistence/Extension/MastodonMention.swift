//
//  MastodonMention.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-17.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension MastodonMention {
    public convenience init(mention: Mastodon.Entity.Mention) {
        self.init(
            id: mention.id,
            username: mention.username,
            acct: mention.acct,
            url: mention.url
        )
    }
}
