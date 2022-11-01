//
//  Mastodon+Entity+History.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/4/2.
//

import MastodonSDK

extension Mastodon.Entity.History: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uses)
        hasher.combine(accounts)
        hasher.combine(day)
    }
    
    public static func == (lhs: Mastodon.Entity.History, rhs: Mastodon.Entity.History) -> Bool {
        return lhs.uses == rhs.uses && lhs.uses == rhs.uses && lhs.day == rhs.day
    }
}
