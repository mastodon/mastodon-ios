//
//  Persistence+MastodonPoll.swift
//
//
//  Created by MainasuK on 2021-12-9.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension Persistence.Poll {

    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Poll
        public let me: MastodonUser?
        public let networkDate: Date
        public init(
            domain: String,
            entity: Mastodon.Entity.Poll,
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
        public let poll: PollLegacy
        public let isNewInsertion: Bool
        
        public init(
            poll: PollLegacy,
            isNewInsertion: Bool
        ) {
            self.poll = poll
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(in: managedObjectContext, poll: old, context: context)
            return PersistResult(
                poll: old,
                isNewInsertion: false
            )
        } else {
            let poll = create(
                in: managedObjectContext,
                context: context
            )

            return PersistResult(
                poll: poll,
                isNewInsertion: true
            )
        }
    }
    
}

extension Persistence.Poll {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PollLegacy? {
        let request = PollLegacy.sortedFetchRequest
        request.predicate = PollLegacy.predicate(domain: context.domain, id: context.entity.id)
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
    ) -> PollLegacy {
        let property = PollLegacy.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        let poll = PollLegacy.insert(
            into: managedObjectContext,
            property: property
        )
        update(in: managedObjectContext, poll: poll, context: context)
        return poll
    }
    
    public static func merge(
        in managedObjectContext: NSManagedObjectContext,
        poll: PollLegacy,
        context: PersistContext
    ) {
        guard context.networkDate > poll.updatedAt else { return }
        let property = PollLegacy.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        poll.update(property: property)
        update(in: managedObjectContext, poll: poll, context: context)
    }
    
    public static func update(
        in managedObjectContext: NSManagedObjectContext,
        poll: PollLegacy,
        context: PersistContext
    ) {
        if let me = context.me {
            if let voted = context.entity.voted {
                poll.update(voted: voted, by: me)
            }
        }
        
        poll.update(updatedAt: context.networkDate)
    }
}
