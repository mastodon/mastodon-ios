//
//  APIService+Persist+PersistCache.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-3-10.
//

import Foundation
import CoreDataStack
import MastodonSDK

extension APIService.Persist {

    class PersistCache<T> {
        var dictionary: [String : T] = [:]
    }

}

extension APIService.Persist.PersistCache where T == Status {

    static func ids(for statuses: [Mastodon.Entity.Status]) -> Set<Mastodon.Entity.Status.ID> {
        var value = Set<String>()
        for status in statuses {
            value = value.union(ids(for: status))
        }
        return value
    }
    
    static func ids(for status: Mastodon.Entity.Status) -> Set<Mastodon.Entity.Status.ID> {
        var value = Set<String>()
        value.insert(status.id)
        if let inReplyToID = status.inReplyToID {
            value.insert(inReplyToID)
        }
        if let reblog = status.reblog {
            value = value.union(ids(for: reblog))
        }
        return value
    }
    
}

extension APIService.Persist.PersistCache where T == MastodonUser {

    static func ids(for statuses: [Mastodon.Entity.Status]) -> Set<Mastodon.Entity.Account.ID> {
        var value = Set<String>()
        for status in statuses {
            value = value.union(ids(for: status))
        }
        return value
    }
    
    static func ids(for status: Mastodon.Entity.Status) -> Set<Mastodon.Entity.Account.ID> {
        var value = Set<String>()
        value.insert(status.account.id)
        if let inReplyToAccountID = status.inReplyToAccountID {
            value.insert(inReplyToAccountID)
        }
        if let reblog = status.reblog {
            value = value.union(ids(for: reblog))
        }
        return value
    }
    
}
