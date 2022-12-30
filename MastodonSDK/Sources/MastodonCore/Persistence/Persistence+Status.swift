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
import os.log

extension Persistence.Status {
    
    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Status
        public let me: MastodonUser?
        public let statusCache: Persistence.PersistCache<Status>?
        public let userCache: Persistence.PersistCache<MastodonUser>?
        public let networkDate: Date
        public let log = Logger(subsystem: "Status", category: "Persistence")

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
        public let isNewInsertionAuthor: Bool
        
        public init(
            status: Status,
            isNewInsertion: Bool,
            isNewInsertionAuthor: Bool
        ) {
            self.status = status
            self.isNewInsertion = isNewInsertion
            self.isNewInsertionAuthor = isNewInsertionAuthor
        }
        
        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.Status.PersistResult", category: "Persist")
        public func log() {
            let statusInsertionFlag = isNewInsertion ? "+" : "-"
            let authorInsertionFlag = isNewInsertionAuthor ? "+" : "-"
            let contentPreview = status.content.prefix(32).replacingOccurrences(of: "\n", with: " ")
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(statusInsertionFlag)](\(status.id))[\(authorInsertionFlag)](\(status.author.id))@\(status.author.username): \(contentPreview)")
        }
        #endif
    }
    
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
                isNewInsertion: false,
                isNewInsertionAuthor: false
            )
        } else {
            let poll: Poll? = {
                guard let entity = context.entity.poll else { return nil }
                let result = Persistence.Poll.createOrMerge(
                    in: managedObjectContext,
                    context: Persistence.Poll.PersistContext(
                        domain: context.domain,
                        entity: entity,
                        me: context.me,
                        networkDate: context.networkDate
                    )
                )
                return result.poll
            }()

            let card = createCard(in: managedObjectContext, context: context)

            let authorResult = Persistence.MastodonUser.createOrMerge(
                in: managedObjectContext,
                context: Persistence.MastodonUser.PersistContext(
                    domain: context.domain,
                    entity: context.entity.account,
                    cache: context.userCache,
                    networkDate: context.networkDate
                )
            )
            let author = authorResult.user
                
            let relationship = Status.Relationship(
                author: author,
                reblog: reblog,
                poll: poll,
                card: card
            )
            let status = create(
                in: managedObjectContext,
                context: context,
                relationship: relationship
            )

            return PersistResult(
                status: status,
                isNewInsertion: true,
                isNewInsertionAuthor: authorResult.isNewInsertion
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
        update(status: status, context: context)
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
        if let poll = status.poll, let entity = context.entity.poll {
            Persistence.Poll.merge(
                poll: poll,
                context: Persistence.Poll.PersistContext(
                    domain: context.domain,
                    entity: entity,
                    me: context.me,
                    networkDate: context.networkDate
                )
            )
        }

        if status.card == nil, context.entity.card != nil {
            let card = createCard(in: managedObjectContext, context: context)
            let relationship = Card.Relationship(status: status)
            card?.configure(relationship: relationship)
        }

        update(status: status, context: context)
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
    
    private static func update(
        status: Status,
        context: PersistContext
    ) {
        // update friendships
        if let user = context.me {
            context.entity.reblogged.flatMap { status.update(reblogged: $0, by: user) }
            context.entity.favourited.flatMap { status.update(liked: $0, by: user) }
        }
    }
    
}
