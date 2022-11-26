//
//  Persistence+MastodonUser.swift
//  Persistence+MastodonUser
//
//  Created by Cirno MainasuK on 2021-8-18.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.MastodonUser {
    
    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Account
        public let cache: Persistence.PersistCache<MastodonUser>?
        public let networkDate: Date
        public let log = Logger(subsystem: "MastodonUser", category: "Persistence")

        public init(
            domain: String,
            entity: Mastodon.Entity.Account,
            cache: Persistence.PersistCache<MastodonUser>?,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.cache = cache
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let user: MastodonUser
        public let isNewInsertion: Bool
        
        public init(
            user: MastodonUser,
            isNewInsertion: Bool
        ) {
            self.user = user
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let oldMastodonUser = fetch(in: managedObjectContext, context: context) {
            merge(mastodonUser: oldMastodonUser, context: context)
            return PersistResult(user: oldMastodonUser, isNewInsertion: false)
        } else {
            let user = create(in: managedObjectContext, context: context)
            return PersistResult(user: user, isNewInsertion: true)
        }
    }
    
}

extension Persistence.MastodonUser {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonUser? {
        if let cache = context.cache {
            return cache.dictionary[context.entity.id]
        } else {
            let request = MastodonUser.sortedFetchRequest
            request.predicate = MastodonUser.predicate(
                domain: context.domain,
                id: context.entity.id
            )
            request.fetchLimit = 1
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
    }
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> MastodonUser {
        let property = MastodonUser.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        let user = MastodonUser.insert(into: managedObjectContext, property: property)
        return user
    }
    
    public static func merge(
        mastodonUser user: MastodonUser,
        context: PersistContext
    ) {
        guard context.networkDate > user.updatedAt else { return }
        let property = MastodonUser.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        user.update(property: property)
    }
    
    private static func update(
        mastodonUser user: MastodonUser,
        context: PersistContext
    ) {
        // TODO:
    }   // end func update

}

extension Persistence.MastodonUser {
    public struct RelationshipContext {
        public let entity: Mastodon.Entity.Relationship
        public let me: MastodonUser
        public let networkDate: Date
        public let log = Logger(subsystem: "MastodonUser", category: "Persistence")

        public init(
            entity: Mastodon.Entity.Relationship,
            me: MastodonUser,
            networkDate: Date
        ) {
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }

    public static func update(
        mastodonUser user: MastodonUser,
        context: RelationshipContext
    ) {
        guard context.entity.id != context.me.id else { return }    // not update relationship for self

        let relationship = context.entity
        let me = context.me
        
        user.update(isFollowing: relationship.following, by: me)
        relationship.requested.flatMap { user.update(isFollowRequested: $0, by: me) }
        // relationship.endorsed.flatMap { user.update(isEndorsed: $0, by: me) }
        me.update(isFollowing: relationship.followedBy, by: user)
        relationship.muting.flatMap { user.update(isMuting: $0, by: me) }
        user.update(isBlocking: relationship.blocking, by: me)
        relationship.domainBlocking.flatMap { user.update(isDomainBlocking: $0, by: me) }
        relationship.blockedBy.flatMap { me.update(isBlocking: $0, by: user) }
        relationship.showingReblogs.flatMap { me.update(isShowingReblogs: $0, by: user) }
    }
}
