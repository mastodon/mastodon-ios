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

extension APIService.Persist.PersistCache where T == Toot {

    static func ids(for toots: [Mastodon.Entity.Status]) -> Set<Mastodon.Entity.Status.ID> {
        var value = Set<String>()
        for toot in toots {
            value = value.union(ids(for: toot))
        }
        return value
    }
    
    static func ids(for toot: Mastodon.Entity.Status) -> Set<Mastodon.Entity.Status.ID> {
        var value = Set<String>()
        value.insert(toot.id)
        if let inReplyToID = toot.inReplyToID {
            value.insert(inReplyToID)
        }
        if let reblog = toot.reblog {
            value = value.union(ids(for: reblog))
        }
        return value
    }
    
}

extension APIService.Persist.PersistCache where T == MastodonUser {

    static func ids(for toots: [Mastodon.Entity.Status]) -> Set<Mastodon.Entity.Account.ID> {
        var value = Set<String>()
        for toot in toots {
            value = value.union(ids(for: toot))
        }
        return value
    }
    
    static func ids(for toot: Mastodon.Entity.Status) -> Set<Mastodon.Entity.Account.ID> {
        var value = Set<String>()
        value.insert(toot.account.id)
        if let inReplyToAccountID = toot.inReplyToAccountID {
            value.insert(inReplyToAccountID)
        }
        if let reblog = toot.reblog {
            value = value.union(ids(for: reblog))
        }
        return value
    }
    
}
