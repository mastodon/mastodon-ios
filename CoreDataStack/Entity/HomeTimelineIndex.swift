//
//  HomeTimelineIndex.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation
import CoreData

final class HomeTimelineIndex: NSManagedObject {
    
    public typealias ID = String
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var userIdentifier: String
    
    @NSManaged public private(set) var createdAt: Date
    
    // many-to-one relationship
    @NSManaged public private(set) var toots: Toots
    
}

extension HomeTimelineIndex {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        toots: Toots
    ) -> HomeTimelineIndex {
        let index: HomeTimelineIndex = context.insertObject()
        
        index.identifier = property.identifier
        index.domain = property.domain
        index.userIdentifier = toots.author.identifier
        index.createdAt = toots.createdAt
        
        index.toots = toots
        
        return index
    }
    
}

extension HomeTimelineIndex {
    public struct Property {
        public let identifier: String
        public let domain: String
    
        public init(domain: String) {
            self.identifier = UUID().uuidString + "@" + domain
            self.domain = domain
        }
    }
}

extension HomeTimelineIndex: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \HomeTimelineIndex.createdAt, ascending: false)]
    }
}

