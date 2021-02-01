//
//  History.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import Foundation
import CoreData

final public class History: NSManagedObject {
    
    public typealias ID = String
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var day: Date
    @NSManaged public private(set) var uses: Int
    @NSManaged public private(set) var accounts: Int
    @NSManaged public private(set) var tag: Tag?
}

extension History {
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property:Property
    ) -> History {
        let history :History = context.insertObject()
        
       history.identifier = UUID().uuidString
       history.day = property.day
       history.uses = property.uses
       history.accounts = property.accounts
        return history
    }
}

extension History {
    public struct Property {
        
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
        return [NSSortDescriptor(keyPath: \History.identifier, ascending: false)]
    }
}
