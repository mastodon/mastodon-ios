//
//  Persistence+Notification.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-21.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log
import class CoreDataStack.Notification

extension Persistence.Notification {
    
    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Notification
        public let me: MastodonUser
        public let networkDate: Date
        public let log = Logger(subsystem: "Notification", category: "Persistence")

        public init(
            domain: String,
            entity: Mastodon.Entity.Notification,
            me: MastodonUser,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.me = me
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let notification: Notification
        public let isNewInsertion: Bool
        
        public init(
            notification: Notification,
            isNewInsertion: Bool
        ) {
            self.notification = notification
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(object: old, context: context)
            return PersistResult(
                notification: old,
                isNewInsertion: false
            )
        } else {
            let accountResult = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: context.domain,
                    entity: context.entity.account,
                    cache: nil,
                    networkDate: context.networkDate
                )
            )
            let account = accountResult.user
            
            let status: Status? = {
                guard let entity = context.entity.status else { return nil }
                let result = Persistence.Status.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Status.PersistContext(
                        domain: context.domain,
                        entity: entity,
                        me: context.me,
                        statusCache: nil,
                        userCache: nil,
                        networkDate: context.networkDate
                    )
                )
                return result.status
            }()
                            
            let relationship = Notification.Relationship(
                account: account,
                status: status
            )
            
            let object = create(
                in: managedObjectContext,
                context: context,
                relationship: relationship
            )

            return PersistResult(
                notification: object,
                isNewInsertion: true
            )
        }
    }
    
}

extension Persistence.Notification {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> Notification? {
        let request = Notification.sortedFetchRequest
        request.predicate = Notification.predicate(
            domain: context.me.domain,
            userID: context.me.id,
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
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext,
        relationship: Notification.Relationship
    ) -> Notification {
        let property = Notification.Property(
            entity: context.entity,
            domain: context.me.domain,
            userID: context.me.id,
            networkDate: context.networkDate
        )
        let object = Notification.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        update(object: object, context: context)
        return object
    }
    
    public static func merge(
        object: Notification,
        context: PersistContext
    ) {
        guard context.networkDate > object.updatedAt else { return }
        let property = Notification.Property(
            entity: context.entity,
            domain: context.me.domain,
            userID: context.me.id,
            networkDate: context.networkDate
        )
        object.update(property: property)
        
        if let status = object.status, let entity = context.entity.status {
            let property = Status.Property(
                entity: entity,
                domain: context.domain,
                networkDate: context.networkDate
            )
            status.update(property: property)
        }
        
        let accountProperty = MastodonUser.Property(
            entity: context.entity.account,
            domain: context.domain,
            networkDate: context.networkDate
        )
        object.account.update(property: accountProperty)
        
        if let author = object.status, let entity = context.entity.status {
            let property = Status.Property(
                entity: entity,
                domain: context.domain,
                networkDate: context.networkDate
            )
            author.update(property: property)
        }
        
        update(object: object, context: context)
    }
    
    private static func update(
        object: Notification,
        context: PersistContext
    ) {
        // do nothing
    }
    
}
