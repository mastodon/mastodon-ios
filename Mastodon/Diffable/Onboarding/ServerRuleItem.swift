//
//  ServerRuleItem.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-5.
//

import Foundation
import MastodonSDK

enum ServerRuleItem: Hashable {
    case header(domain: String)
    case rule(RuleContext)
}

extension ServerRuleItem {
    struct RuleContext: Hashable {
        let index: Int
        let rule: Mastodon.Entity.Instance.Rule
    }
}
