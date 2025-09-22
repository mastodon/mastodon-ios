//
//  AutoCompleteItem.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-5-17.
//

import Foundation
import MastodonSDK

public enum AutoCompleteItem {
    case hashtag(tag: Mastodon.Entity.Tag)
    case hashtagV1(tag: String)
    case account(account: Mastodon.Entity.Account)
    case emoji(emoji: Mastodon.Entity.Emoji)
    case bottomLoader
}

extension AutoCompleteItem: Equatable {
    public static func == (lhs: AutoCompleteItem, rhs: AutoCompleteItem) -> Bool {
        switch (lhs, rhs) {
        case (.hashtag(let tagLeft), hashtag(let tagRight)):
            return tagLeft.name == tagRight.name && tagLeft.url == tagRight.url
        case (.hashtagV1(let tagLeft), hashtagV1(let tagRight)):
            return tagLeft == tagRight
        case (.account(let accountLeft), account(let accountRight)):
            return accountLeft.id == accountRight.id
        case (.emoji(let emojiLeft), .emoji(let emojiRight)):
            return emojiLeft.shortcode == emojiRight.shortcode && emojiLeft.url == emojiRight.url
        case (.bottomLoader, .bottomLoader):
            return true
        default:
            return false
        }
    }
}

extension AutoCompleteItem: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .hashtag(let tag):
            hasher.combine(tag.name)
            hasher.combine(tag.url)
        case .hashtagV1(let tag):
            hasher.combine(tag)
        case .account(let account):
            hasher.combine(account.id)
        case .emoji(let emoji):
            hasher.combine(emoji.shortcode)
            hasher.combine(emoji.url)
        case .bottomLoader:
            hasher.combine(String(describing: AutoCompleteItem.bottomLoader.self))
        }
    }
}
