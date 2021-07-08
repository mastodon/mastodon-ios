//
//  Mastodon+Entity+Account.swift
//  Mastodon
//
//  Created by xiaojian sun on 2021/4/2.
//

import UIKit
import MastodonSDK

extension Mastodon.Entity.Account: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Mastodon.Entity.Account, rhs: Mastodon.Entity.Account) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Mastodon.Entity.Account {
    public func avatarImageURL() -> URL? {
        let string = UserDefaults.shared.preferredStaticAvatar ? avatarStatic ?? avatar : avatar
        return URL(string: string)
    }

    public func avatarImageURLWithFallback(domain: String) -> URL {
        return avatarImageURL() ?? URL(string: "https://\(domain)/avatars/original/missing.png")!
    }
}
