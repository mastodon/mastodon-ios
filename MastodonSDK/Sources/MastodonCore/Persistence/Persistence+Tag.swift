//
//  Persistence+Tag.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.Tag {
    
    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Tag
        public let me: MastodonUser?
        public let networkDate: Date
        public let log = Logger(subsystem: "Tag", category: "Persistence")
        
        public init(
            domain: String,
            entity: Mastodon.Entity.Tag,
            me: MastodonUser?,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let tag: Tag
        public let isNewInsertion: Bool
        
        public init(
            tag: Tag,
            isNewInsertion: Bool
        ) {
            self.tag = tag
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(tag: old, context: context)
            return PersistResult(
                tag: old,
                isNewInsertion: false
            )
        } else {
            let object = create(
                in: managedObjectContext,
                context: context
            )

            return PersistResult(
                tag: object,
                isNewInsertion: false
            )
        }
    }
    
}

extension Persistence.Tag {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> Tag? {
        let request = Tag.sortedFetchRequest
        request.predicate = Tag.predicate(domain: context.domain, name: context.entity.name)
        request.fetchLimit = 1
        do {
            return try managedObjectContext.fetch(request).first
        } catch {
            assertionFailure(error.localizedDescription)
            return nil
        }
    }
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> Tag {
        let property = Tag.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        let object = Tag.insert(
            into: managedObjectContext,
            property: property
        )
        update(tag: object, context: context)
        if let followingUser = context.me {
            object.update(followed: property.following, by: followingUser)
        }
        return object
    }
    
    public static func merge(
        tag: Tag,
        context: PersistContext
    ) {
        guard context.networkDate > tag.updatedAt else { return }
        let property = Tag.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )

        tag.update(property: property)
        if let followingUser = context.me {
            tag.update(followed: property.following, by: followingUser)
        }
        update(tag: tag, context: context)
    }
    
    private static func update(
        tag: Tag,
        context: PersistContext
    ) {
        tag.update(updatedAt: context.networkDate)
    }
    
}
