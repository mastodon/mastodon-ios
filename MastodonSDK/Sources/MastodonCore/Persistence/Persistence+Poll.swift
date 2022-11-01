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
import os.log

extension Persistence.Poll {

    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.Poll
        public let me: MastodonUser?
        public let networkDate: Date
        public let log = Logger(subsystem: "Poll", category: "Persistence")
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
        public let poll: Poll
        public let isNewInsertion: Bool
        
        public init(
            poll: Poll,
            isNewInsertion: Bool
        ) {
            self.poll = poll
            self.isNewInsertion = isNewInsertion
        }
        
        #if DEBUG
        public let logger = Logger(subsystem: "Persistence.MastodonPoll.PersistResult", category: "Persist")
        public func log() {
            let pollInsertionFlag = isNewInsertion ? "+" : "-"
            logger.log(level: .debug, "\((#file as NSString).lastPathComponent, privacy: .public)[\(#line, privacy: .public)], \(#function, privacy: .public): [\(pollInsertionFlag)](\(poll.id)):")
        }
        #endif
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        
        if let old = fetch(in: managedObjectContext, context: context) {
            merge(poll: old, context: context)
            return PersistResult(
                poll: old,
                isNewInsertion: false
            )
        } else {
            let options: [PollOption] = context.entity.options.enumerated().map { i, entity in
                let optionResult = Persistence.PollOption.persist(
                    in: managedObjectContext,
                    context: Persistence.PollOption.PersistContext(
                        index: i,
                        entity: entity,
                        me: context.me,
                        networkDate: context.networkDate
                    )
                )
                return optionResult.option
            }
            
            let poll = create(
                in: managedObjectContext,
                context: context
            )
            poll.attach(options: options)

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
    ) -> Poll? {
        let request = Poll.sortedFetchRequest
        request.predicate = Poll.predicate(domain: context.domain, id: context.entity.id)
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
    ) -> Poll {
        let property = Poll.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        let poll = Poll.insert(
            into: managedObjectContext,
            property: property
        )
        update(poll: poll, context: context)
        return poll
    }
    
    public static func merge(
        poll: Poll,
        context: PersistContext
    ) {
        guard context.networkDate > poll.updatedAt else { return }
        let property = Poll.Property(
            entity: context.entity,
            domain: context.domain,
            networkDate: context.networkDate
        )
        poll.update(property: property)
        update(poll: poll, context: context)
    }
    
    public static func update(
        poll: Poll,
        context: PersistContext
    ) {
        let optionEntities = context.entity.options
        let options = poll.options.sorted(by: { $0.index < $1.index })
        for (option, entity) in zip(options, optionEntities) {
            Persistence.PollOption.merge(
                option: option,
                context: Persistence.PollOption.PersistContext(
                    index: Int(option.index),
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
        
        poll.update(updatedAt: context.networkDate)
    }
    
}
