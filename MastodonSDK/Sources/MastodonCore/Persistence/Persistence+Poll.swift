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
        let optionEntities = context.entity.options
        let options = poll.options.sorted(by: { $0.index < $1.index })
        for (option, entity) in zip(options, optionEntities) {
            Persistence.PollOption.merge(
                option: option,
                context: Persistence.PollOption.PersistContext(
                    index: Int(option.index),
                    poll: poll,
                    entity: entity,
                    me: context.me,
                    networkDate: context.networkDate
                )
            )
        }   // end for in
        
        if let me = context.me {
            if let voted = context.entity.voted {
                poll.update(voted: voted, by: me)
            }
            
            let ownVotes = context.entity.ownVotes ?? []
            for option in options {
                let index = Int(option.index)
                let isVote = ownVotes.contains(index)
                option.update(voted: isVote, by: me)
            }
        }
        
        // update options
        if needsPollOptionsUpdate(context: context, poll: poll) {
            // options differ, update them
            for option in poll.options {
                option.update(poll: nil)
                managedObjectContext.delete(option)
            }
            var attachableOptions = [PollOptionLegacy]()
            for (index, option) in context.entity.options.enumerated() {
                attachableOptions.append(
                    Persistence.PollOption.create(
                        in: managedObjectContext,
                        context: Persistence.PollOption.PersistContext(
                            index: index,
                            poll: poll,
                            entity: option,
                            me: context.me,
                            networkDate: context.networkDate
                        )
                    )
                )
            }
            poll.attach(options: attachableOptions)
        }
        
        poll.update(updatedAt: context.networkDate)
    }
    
    private static func needsPollOptionsUpdate(context: PersistContext, poll: PollLegacy) -> Bool {
        let entityPollOptions = context.entity.options.map { (title: $0.title, votes: $0.votesCount) }
        let pollOptions = poll.options.sortedByIndex().map { (title: $0.title, votes: Int($0.votesCount)) }
        
        guard entityPollOptions.count == pollOptions.count else {
            // poll definitely needs to be updated due to differences in count of options
            return true
        }
        
        for (entityPollOption, pollOption) in zip(entityPollOptions, pollOptions) {
            guard entityPollOption.title == pollOption.title else {
                // update poll because at least one title differs
                return true
            }
            guard entityPollOption.votes == pollOption.votes else {
                // update poll because at least one vote count differs
                return true
            }
        }
        return false
    }
}
