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

extension Mastodon.Entity.Tag {
    
    /// the sum of recent 2 days
    public var talkingPeopleCount: Int? {
        return history?
            .prefix(2)
            .compactMap { Int($0.accounts) }
            .reduce(0, +)
    }
    
}
