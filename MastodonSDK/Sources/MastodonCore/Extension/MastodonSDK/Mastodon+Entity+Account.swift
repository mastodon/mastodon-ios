//
//  Mastodon+Entity+Account.swift
//  
//
//  Created by MainasuK on 2022-5-16.
//

import Foundation
import MastodonSDK
import MastodonMeta

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

extension Mastodon.Entity.Account {
    public var displayNameWithFallback: String {
        return !displayName.isEmpty ? displayName : username
    }
}

extension Mastodon.Entity.Account {
    public var emojiMeta: MastodonContent.Emojis {
        let isAnimated = !UserDefaults.shared.preferredStaticEmoji

        var dict = MastodonContent.Emojis()
        for emoji in emojis ?? [] {
            dict[emoji.shortcode] = isAnimated ? emoji.url : emoji.staticURL
        }
        return dict
    }
}
