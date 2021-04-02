//
//  Mention.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class Mention: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var id: String
    @NSManaged public private(set) var createAt: Date

    @NSManaged public private(set) var username: String
    @NSManaged public private(set) var acct: String
    @NSManaged public private(set) var url: String

    // many-to-one relationship
    @NSManaged public private(set) var status: Status
}

public extension Mention {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID(), forKey: #keyPath(Mention.identifier))
    }

    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Mention {
        let mention: Mention = context.insertObject()
        mention.id = property.id
        mention.username = property.username
        mention.acct = property.acct
        mention.url = property.url
        return mention
    }
}

public extension Mention {
    struct Property {
        public let id: String
        public let username: String
        public let acct: String
        public let url: String

        public init(id: String, username: String, acct: String, url: String) {
            self.id = id
            self.username = username
            self.acct = acct
            self.url = url
        }
    }
}

extension Mention: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Mention.createAt, ascending: false)]
    }
}
