//
//  Tag.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class Tag: NSManagedObject {
    public typealias ID = String
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var url: String
    //on to many
    @NSManaged public private(set) var history: [History]?
}

public extension Tag {
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Tag {
        let Tag: Tag = context.insertObject()

        Tag.identifier = UUID().uuidString
        Tag.name = property.name
        Tag.url = property.url
        Tag.history = property.history
        return Tag
    }
}

public extension Tag {
    struct Property {
        public let name: String
        public let url: String
        public let history: [History]?

        public init(name: String, url: String, history: [History]?) {
            self.name = name
            self.url = url
            self.history = history
        }
    }
}

extension Tag: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Tag.identifier, ascending: false)]
    }
}
