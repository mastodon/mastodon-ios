//
//  Tag.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class Tag: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var createAt: Date
    
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var url: String
    
    // one-to-many relationship
    @NSManaged public private(set) var histories: Set<History>?
}

public extension Tag {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Tag {
        let tag: Tag = context.insertObject()
        tag.name = property.name
        tag.url = property.url
        if let histories = property.histories {
            tag.mutableSetValue(forKey: #keyPath(Tag.histories)).addObjects(from: histories)
        }
        return tag
    }
}

public extension Tag {
    struct Property {
        public let name: String
        public let url: String
        public let histories: [History]?

        public init(name: String, url: String, histories: [History]?) {
            self.name = name
            self.url = url
            self.histories = histories
        }
    }
}

extension Tag: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Tag.createAt, ascending: false)]
    }
}
