//
//  Toot.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation
import CoreData

final public class Toot: NSManagedObject {
    
    public typealias ID = String
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var domain: String
    
    @NSManaged public private(set) var id: String
    @NSManaged public private(set) var content: String
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var deletedAt: Date?
    
    // many-to-one relationship
    @NSManaged public private(set) var author: MastodonUser
    
    // one-to-many relationship
    @NSManaged public private(set) var homeTimelineIndexes: Set<HomeTimelineIndex>?
    
}

extension Toot {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        author: MastodonUser
    ) -> Toot {
        let toots: Toot = context.insertObject()
        
        toots.identifier = property.identifier
        toots.domain = property.domain
        
        toots.id = property.id
        toots.content = property.content
        toots.createdAt = property.createdAt
        toots.updatedAt = property.networkDate
        
        toots.author = author
        
        return toots
    }
    
}

extension Toot {
    public struct Property {
        public let identifier: String
        public let domain: String
        
        public let id: String
        public let content: String
        public let createdAt: Date
        public let networkDate: Date
        
        public init(
            id: String,
            domain: String,
            content: String,
            createdAt: Date,
            networkDate: Date
        ) {
            self.identifier = id + "@" + domain
            self.domain = domain
            self.id = id
            self.content = content
            self.createdAt = createdAt
            self.networkDate = networkDate
        }
    }
}

extension Toot: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Toot.createdAt, ascending: false)]
    }
}

extension Toot {
    
    public static func predicate(idStr: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Toot.id), idStr)
    }
    
    public static func predicate(idStrs: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(Toot.id), idStrs)
    }
    
    public static func notDeleted() -> NSPredicate {
        return NSPredicate(format: "%K == nil", #keyPath(Toot.deletedAt))
    }
    
    public static func deleted() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(Toot.deletedAt))
    }
    
}
