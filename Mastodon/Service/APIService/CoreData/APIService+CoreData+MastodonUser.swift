//
//  APIService+CoreData+MastodonUser.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.CoreData {
    
    static func createOrMergeMastodonUser(
        into managedObjectContext: NSManagedObjectContext,
        for requestMastodonUser: MastodonUser?,
        in domain: String,
        entity: Mastodon.Entity.Account,
        userCache: APIService.Persist.PersistCache<MastodonUser>?,
        networkDate: Date,
        log: OSLog
    ) -> (user: MastodonUser, isCreated: Bool) {
        let processEntityTaskSignpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: "update database - process entity: createOrMergeMastodonUser", signpostID: processEntityTaskSignpostID, "process mastodon user %{public}s", entity.id)
        defer {
            os_signpost(.end, log: log, name: "update database - process entity: createOrMergeMastodonUser", signpostID: processEntityTaskSignpostID, "process msstodon user %{public}s", entity.id)
        }
        
        // fetch old mastodon user
        let oldMastodonUser: MastodonUser? = {
            if let userCache = userCache {
                return userCache.dictionary[entity.id]
            } else {
                let request = MastodonUser.sortedFetchRequest
                request.predicate = MastodonUser.predicate(domain: domain, id: entity.id)
                request.fetchLimit = 1
                request.returnsObjectsAsFaults = false
                do {
                    return try managedObjectContext.fetch(request).first
                } catch {
                    assertionFailure(error.localizedDescription)
                    return nil
                }                
            }
        }()
        
        if let oldMastodonUser = oldMastodonUser {
            // merge old mastodon usre
            APIService.CoreData.merge(
                user: oldMastodonUser,
                entity: entity,
                requestMastodonUser: requestMastodonUser,
                domain: domain,
                networkDate: networkDate
            )
            return (oldMastodonUser, false)
        } else {
            let mastodonUserProperty = MastodonUser.Property(entity: entity, domain: domain, networkDate: networkDate)
            let mastodonUser = MastodonUser.insert(
                into: managedObjectContext,
                property: mastodonUserProperty
            )
            userCache?.dictionary[entity.id] = mastodonUser
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeMastodonUser", signpostID: processEntityTaskSignpostID, "did insert new mastodon user %{public}s: name %s", mastodonUser.identifier, mastodonUser.username)
            return (mastodonUser, true)
        }
    }
    
}

extension APIService.CoreData {
    
    static func merge(
        user: MastodonUser,
        entity: Mastodon.Entity.Account,
        requestMastodonUser: MastodonUser?,
        domain: String,
        networkDate: Date
    ) {
        guard networkDate > user.updatedAt else { return }
        let property = MastodonUser.Property(entity: entity, domain: domain, networkDate: networkDate)
        
        // only fulfill API supported fields
        user.update(acct: property.acct)
        user.update(username: property.username)
        user.update(displayName: property.displayName)
        user.update(avatar: property.avatar)
        user.update(avatarStatic: property.avatarStatic)
        user.update(header: property.header)
        user.update(headerStatic: property.headerStatic)
        user.update(note: property.note)
        user.update(url: property.url)
        user.update(statusesCount: property.statusesCount)
        user.update(followingCount: property.followingCount)
        user.update(followersCount: property.followersCount)
        user.update(locked: property.locked)
        property.bot.flatMap { user.update(bot: $0) }
        property.suspended.flatMap { user.update(suspended: $0) }
        
        user.didUpdate(at: networkDate)
    }
    
}
    
extension APIService.CoreData {

    static func update(
        user: MastodonUser,
        entity: Mastodon.Entity.Relationship,
        requestMastodonUser: MastodonUser,
        domain: String,
        networkDate: Date
    ) {
        guard networkDate > user.updatedAt else { return }
        guard entity.id != requestMastodonUser.id else { return }     // not update relationship for self
        
        user.update(isFollowing: entity.following, by: requestMastodonUser)
        entity.requested.flatMap { user.update(isFollowRequested: $0, by: requestMastodonUser) }
        entity.endorsed.flatMap { user.update(isEndorsed: $0, by: requestMastodonUser) }
        requestMastodonUser.update(isFollowing: entity.followedBy, by: user)
        entity.muting.flatMap { user.update(isMuting: $0, by: requestMastodonUser) }
        user.update(isBlocking: entity.blocking, by: requestMastodonUser)
        entity.domainBlocking.flatMap { user.update(isDomainBlocking: $0, by: requestMastodonUser) }
        entity.blockedBy.flatMap { requestMastodonUser.update(isBlocking: $0, by: user) }
        
        user.didUpdate(at: networkDate)
    }
    
}
