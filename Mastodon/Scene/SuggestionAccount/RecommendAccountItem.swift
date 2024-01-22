//
//  RecommendAccountItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-2-10.
//

import Foundation
import MastodonSDK

enum RecommendAccountItem: Hashable {
    case account(Mastodon.Entity.Account, relationship: Mastodon.Entity.Relationship?)
}
