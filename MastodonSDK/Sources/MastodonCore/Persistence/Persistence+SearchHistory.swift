//
//  Persistence+SearchHistory.swift
//  Mastodon
//
//  Created by MainasuK on 2022-1-20.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK
import os.log

extension Persistence.SearchHistory {
    
    public struct PersistContext {
        public let entity: Entity
        public let me: MastodonUser
        public let now: Date
        public let log = Logger(subsystem: "SearchHistory", category: "Persistence")
        public init(
            entity: Entity,
            me: MastodonUser,
            now: Date
        ) {
            self.entity = entity
            self.me = me
            self.now = now
        }
        
        public enum Entity: Hashable {
            case user(MastodonUser)
            case hashtag(Tag)
        }
    }
    
    public struct PersistResult {
        public let searchHistory: SearchHistory
        public let isNewInsertion: Bool
        
        public init(
            searchHistory: SearchHistory,
            isNewInsertion: Bool
        ) {
            self.searchHistory = searchHistory
            self.isNewInsertion = isNewInsertion
        }
    }
    
    public static func createOrMerge(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> PersistResult {
        if let old = fetch(in: managedObjectContext, context: context) {
            update(searchHistory: old, context: context)
            return PersistResult(searchHistory: old, isNewInsertion: false)
        } else {
            let object = create(in: managedObjectContext, context: context)
            return PersistResult(searchHistory: object, isNewInsertion: true)
        }
    }
    
}

extension Persistence.SearchHistory {
    
    public static func fetch(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> SearchHistory? {
        switch context.entity {
        case .user(let user):
            return user.findSearchHistory(for: context.me)
        case .hashtag(let hashtag):
            return hashtag.findSearchHistory(for: context.me)
        }
    }
    
    @discardableResult
    public static func create(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> SearchHistory {
        let property = SearchHistory.Property(
            identifier: UUID(),
            domain: context.me.domain,
            userID: context.me.id,
            createAt: context.now,
            updatedAt: context.now
        )
        let relationship: SearchHistory.Relationship = {
            switch context.entity {
            case .user(let user):
                return SearchHistory.Relationship(account: user, hashtag: nil, status: nil)
            case .hashtag(let hashtag):
                return SearchHistory.Relationship(account: nil, hashtag: hashtag, status: nil)
            }
        }()
        let searchHistory = SearchHistory.insert(
            into: managedObjectContext,
            property: property,
            relationship: relationship
        )
        update(searchHistory: searchHistory, context: context)
        return searchHistory
    }
    
    private static func update(
        searchHistory: SearchHistory,
        context: PersistContext
    ) {
        searchHistory.update(updatedAt: context.now)
    }

}
