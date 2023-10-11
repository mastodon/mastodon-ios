//
//  ServerRuleItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import Foundation
import MastodonSDK

enum ServerRuleItem: Hashable {
    case rule(index: Int, rule: Mastodon.Entity.Instance.Rule)
}
