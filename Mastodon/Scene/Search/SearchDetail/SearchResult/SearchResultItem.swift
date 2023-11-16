//
//  SearchResultItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import Foundation
import MastodonSDK

enum SearchResultItem: Hashable {
    case user(Mastodon.Entity.Account)
    case status(Mastodon.Entity.Status)
    case hashtag(tag: Mastodon.Entity.Tag)
    case bottomLoader(attribute: BottomLoaderAttribute)
}

extension SearchResultItem {
    class BottomLoaderAttribute: Hashable {
        let id = UUID()

        var isNoResult: Bool

        init(isEmptyResult: Bool) {
            self.isNoResult = isEmptyResult
        }

        static func == (
            lhs: SearchResultItem.BottomLoaderAttribute,
            rhs: SearchResultItem.BottomLoaderAttribute
        ) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}
