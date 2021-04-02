//
//  SearchResultItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import Foundation
import MastodonSDK

enum SearchResultItem {
    case hashTag(tag: Mastodon.Entity.Tag)

    case account(account: Mastodon.Entity.Account)
}

extension SearchResultItem: Equatable {
    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        switch (lhs, rhs) {
        case (.hashTag(let tagLeft), .hashTag(let tagRight)):
            return tagLeft == tagRight
        case (.account(let accountLeft), account(let accountRight)):
            return accountLeft == accountRight
        default:
            return false
        }
    }
}

extension SearchResultItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .account(let account):
            hasher.combine(account)
        case .hashTag(let tag):
            hasher.combine(tag)
        }
    }
}
