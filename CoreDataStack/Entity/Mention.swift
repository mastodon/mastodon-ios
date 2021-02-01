//
//  Mention.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import Foundation
import CoreData

final public class Mention: NSManagedObject {
    
    public typealias ID = String
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var id: String
    @NSManaged public private(set) var username: String
    @NSManaged public private(set) var acct: String
    @NSManaged public private(set) var url: String
    @NSManaged public private(set) var toot: Toot?
}

extension Mention {
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property:Property
    ) -> Mention {
        let mention :Mention = context.insertObject()
        
        mention.identifier = UUID().uuidString
        mention.id = property.id
        mention.username = property.username
        mention.acct = property.acct
        mention.url = property.url
        return mention
    }
}

extension Mention {
    public struct Property {
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
        return [NSSortDescriptor(keyPath: \Mention.id, ascending: false)]
    }
}
