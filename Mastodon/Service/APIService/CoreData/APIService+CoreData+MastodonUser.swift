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
        }()
        
        if let oldMastodonUser = oldMastodonUser {
            // merge old mastodon usre
            APIService.CoreData.mergeMastodonUser(
                for: requestMastodonUser,
                old: oldMastodonUser,
                in: domain,
                entity: entity,
                networkDate: networkDate
            )
            return (oldMastodonUser, false)
        } else {
            let mastodonUserProperty = MastodonUser.Property(entity: entity, domain: domain, networkDate: networkDate)
            let mastodonUser = MastodonUser.insert(
                into: managedObjectContext,
                property: mastodonUserProperty
            )
            
            os_signpost(.event, log: log, name: "update database - process entity: createOrMergeMastodonUser", signpostID: processEntityTaskSignpostID, "did insert new mastodon user %{public}s: name %s", mastodonUser.identifier, mastodonUser.username)
            return (mastodonUser, true)
        }
    }
    
    static func mergeMastodonUser(
        for requestMastodonUser: MastodonUser?,
        old user: MastodonUser,
        in domain: String,
        entity: Mastodon.Entity.Account,
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
        
        user.didUpdate(at: networkDate)
    }
    
}
