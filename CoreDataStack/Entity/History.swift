//
//  History.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class History: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var createAt: Date

    @NSManaged public private(set) var day: Date
    @NSManaged public private(set) var uses: Int
    @NSManaged public private(set) var accounts: Int
    
    // many-to-one relationship
    @NSManaged public private(set) var tag: Tag
}

public extension History {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        identifier = UUID()
    }

    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> History {
        let history: History = context.insertObject()
        history.day = property.day
        history.uses = property.uses
        history.accounts = property.accounts
        return history
    }
}

public extension History {
    struct Property {
        public let day: Date
        public let uses: Int
        public let accounts: Int

        public init(day: Date, uses: Int, accounts: Int) {
            self.day = day
            self.uses = uses
            self.accounts = accounts
        }
    }
}

extension History: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \History.createAt, ascending: false)]
    }
}
