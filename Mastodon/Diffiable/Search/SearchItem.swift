//
//  SearchItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-18.
//

import Foundation
import MastodonSDK

enum SearchItem: Hashable {
    case trend(Mastodon.Entity.Tag)
}
