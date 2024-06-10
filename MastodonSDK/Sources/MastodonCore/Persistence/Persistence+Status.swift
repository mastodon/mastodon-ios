//
//  Persistence+Status.swift
//  Persistence+Status
//
//  Created by Cirno MainasuK on 2021-8-27.
//  Copyright © 2021 Twidere. All rights reserved.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension Persistence.Status {
    
    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Status
        public let me: MastodonUser?
        public let statusCache: Persistence.PersistCache<Status>?
        public let userCache: Persistence.PersistCache<MastodonUser>?
        public let networkDate: Date

        public init(
            domain: String,
            entity: Mastodon.Entity.Status,
            me: MastodonUser?,
            statusCache: Persistence.PersistCache<Status>?,
            userCache: Persistence.PersistCache<MastodonUser>?,
            networkDate: Date
        ) {
            self.domain = domain
            self.entity = entity
            self.me = me
            self.statusCache = statusCache
            self.userCache = userCache
            self.networkDate = networkDate
        }
    }
    
    public struct PersistResult {
        public let status: Status
        public let isNewInsertion: Bool
        
        public init(
            status: Status,
            isNewInsertion: Bool
        ) {
            self.status = status
            self.isNewInsertion = isNewInsertion
        }
    }
    
    @available(*, deprecated, message: "old")
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        
        let reblog = context.entity.reblog.flatMap { entity -> Status in
            let result = createOrMerge(
                in: managedObjectContext,
                context: PersistContext(
                    domain: context.domain,
                    entity: entity,
                    me: context.me,
                    statusCache: context.statusCache,
                    userCache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            return result.status
        }
        
        if let oldStatus = fetch(in: managedObjectContext, context: context) {
            merge(in: managedObjectContext, mastodonStatus: oldStatus, context: context)
            return PersistResult(
                status: oldStatus,
                isNewInsertion: false
            )
        } else {

            let card = createCard(in: managedObjectContext, context: context)

            let application: Application? = createApplication(in: managedObjectContext, context: .init(entity: context.entity))
                
            let relationship = Status.Relationship(
                application: application,
                reblog: reblog,
                card: card
            )
            let status = create(
                in: managedObjectContext,
                context: context,
                relationship: relationship
            )

            return PersistResult(
                status: status,
                isNewInsertion: true
            )
        }
    }
    
}

extension Persistence.Status {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> Status? {
        if let cache = context.statusCache {
            return cache.dictionary[context.entity.id]
        } else {
            let request = Status.sortedFetchRequest
            request.predicate = Status.predicate(domain: context.domain, id: context.entity.id)
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
        context: PersistContext,
        relationship: Status.Relationship
    ) -> Status {
        let property = Status.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        let status = Status.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        return status
    }
    
    public static func merge(
        in managedObjectContext: NSManagedObjectContext,
        mastodonStatus status: Status,
        context: PersistContext
    ) {
        guard context.networkDate > status.updatedAt else { return }
        let property = Status.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        status.update(property: property)

        if status.card == nil, context.entity.card != nil {
            let card = createCard(in: managedObjectContext, context: context)
            let relationship = Card.Relationship(status: status)
            card?.configure(relationship: relationship)
        }
    }

    private static func createCard(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> Card? {
        guard let entity = context.entity.card else { return nil }
        let result = Persistence.Card.create(
            in: managedObjectContext,
            context: Persistence.Card.PersistContext(
                domain: context.domain,
                entity: entity,
                me: context.me
            )
        )
        return result.card
    }

    private static func createApplication(
        in managedObjectContext: NSManagedObjectContext,
        context: MastodonApplication.PersistContext
    ) -> Application? {
        guard let application = context.entity.application else { return nil }

        let persistedApplication = Application.insert(into: managedObjectContext, property: .init(name: application.name, website: application.website, vapidKey: application.vapidKey))

        return persistedApplication
    }

    enum MastodonApplication {
        public struct PersistContext {
            let entity: Mastodon.Entity.Status
        }
    }
}
