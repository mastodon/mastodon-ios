//
//  SearchHistoryItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-7-15.
//

import Foundation
import MastodonSDK

enum SearchHistoryItem: Hashable {
    case hashtag(Mastodon.Entity.Tag)
    case account(Mastodon.Entity.Account)
}
