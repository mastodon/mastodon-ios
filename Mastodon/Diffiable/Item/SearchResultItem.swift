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
    case hashTag(tag: Mastodon.Entity.Tag)

    case account(account: Mastodon.Entity.Account)

    case accountObjectID(accountObjectID: NSManagedObjectID)

    case hashTagObjectID(hashTagObjectID: NSManagedObjectID)

    case bottomLoader
}

extension SearchResultItem: Equatable {
    static func == (lhs: SearchResultItem, rhs: SearchResultItem) -> Bool {
        switch (lhs, rhs) {
        case (.hashTag(let tagLeft), .hashTag(let tagRight)):
            return tagLeft == tagRight
        case (.account(let accountLeft), .account(let accountRight)):
            return accountLeft == accountRight
        case (.bottomLoader, .bottomLoader):
            return true
        case (.accountObjectID(let idLeft),.accountObjectID(let idRight)):
            return idLeft == idRight
        case (.hashTagObjectID(let idLeft),.hashTagObjectID(let idRight)):
            return idLeft == idRight
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
        case .accountObjectID(let id):
            hasher.combine(id)
        case .hashTagObjectID(let id):
            hasher.combine(id)
        case .bottomLoader:
            hasher.combine(String(describing: SearchResultItem.bottomLoader.self))
        }
    }
}
