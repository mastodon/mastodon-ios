//
//  SearchResultItem.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/6.
//

import CoreData
import Foundation
import MastodonSDK

enum SearchResultItem {
    case hashtag(tag: Mastodon.Entity.Tag)
    case account(account: Mastodon.Entity.Account)

    case accountObjectID(accountObjectID: NSManagedObjectID)
    case hashtagObjectID(hashtagObjectID: NSManagedObjectID)
    case status(statusObjectID: NSManagedObjectID, attribute: Item.StatusAttribute)

    case bottomLoader(attribute: BottomLoaderAttribute)
}

extension SearchResultItem {
    class BottomLoaderAttribute: Hashable {
        let id = UUID()

        var isNoResult: Bool

        init(isEmptyResult: Bool) {
            self.isNoResult = isEmptyResult
        }

        static func == (lhs: SearchResultItem.BottomLoaderAttribute, rhs: SearchResultItem.BottomLoaderAttribute) -> Bool {
            return lhs.id == rhs.id
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
}

extension SearchResultItem: Equatable {
    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        switch (lhs, rhs) {
        case (.hashtag(let tagLeft), .hashtag(let tagRight)):
            return tagLeft == tagRight
        case (.account(let accountLeft), .account(let accountRight)):
            return accountLeft == accountRight
        case (.accountObjectID(let idLeft), .accountObjectID(let idRight)):
            return idLeft == idRight
        case (.hashtagObjectID(let idLeft), .hashtagObjectID(let idRight)):
            return idLeft == idRight
        case (.status(let idLeft, _), .status(let idRight, _)):
            return idLeft == idRight
        case (.bottomLoader(let attributeLeft), .bottomLoader(let attributeRight)):
            return attributeLeft == attributeRight
        default:
            return false
        }
    }
}

extension SearchResultItem: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self {
        case .account(let account):
            hasher.combine(String(describing: SearchResultItem.account.self))
            hasher.combine(account.id)
        case .hashtag(let tag):
            hasher.combine(String(describing: SearchResultItem.hashtag.self))
            hasher.combine(tag.name)
        case .accountObjectID(let id):
            hasher.combine(id)
        case .hashtagObjectID(let id):
            hasher.combine(id)
        case .status(let id, _):
            hasher.combine(id)
        case .bottomLoader(let attribute):
            hasher.combine(attribute)
        }
    }
}

extension SearchResultItem {
    var sortKey: String? {
        switch self {
        case .account(let account): return account.displayName.lowercased()
        case .hashtag(let hashtag): return hashtag.name.lowercased()
        default:                    return nil
        }
    }
}

extension SearchResultItem {
    var statusObjectItem: StatusObjectItem? {
        switch self {
        case .status(let objectID, _):
            return .status(objectID: objectID)
        case .hashtag,
             .account,
             .accountObjectID,
             .hashtagObjectID,
             .bottomLoader:
            return nil
        }
    }
}
