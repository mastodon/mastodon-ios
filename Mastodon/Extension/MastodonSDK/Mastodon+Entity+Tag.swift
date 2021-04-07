//
//  Mastodon+Entity+Tag.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/4/2.
//

import MastodonSDK

extension Mastodon.Entity.Tag: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
    
    public static func == (lhs: Mastodon.Entity.Tag, rhs: Mastodon.Entity.Tag) -> Bool {
        return lhs.name == rhs.name
    }
}
