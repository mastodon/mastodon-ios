//
//  DomainBlock.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/4/29.
//

import CoreData
import Foundation

public final class DomainBlock: NSManagedObject {
    @NSManaged public private(set) var blockedDomain: String
    @NSManaged public private(set) var createAt: Date

    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var userID: String

    override public func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: #keyPath(DomainBlock.createAt))
    }
}

extension DomainBlock {
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        blockedDomain: String,
        domain: String,
        userID: String
    ) -> DomainBlock {
        let domainBlock: DomainBlock = context.insertObject()
        domainBlock.domain = domain
        domainBlock.blockedDomain = blockedDomain
        domainBlock.userID = userID
        return domainBlock
    }
}

extension DomainBlock: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \DomainBlock.createAt, ascending: false)]
    }
}

extension DomainBlock {
    static func predicate(domain: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(DomainBlock.domain), domain)
    }

    static func predicate(userID: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(DomainBlock.userID), userID)
    }

    static func predicate(blockedDomain: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(DomainBlock.blockedDomain), blockedDomain)
    }

    public static func predicate(domain: String, userID: String) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            DomainBlock.predicate(domain: domain),
            DomainBlock.predicate(userID: userID)
        ])
    }

    public static func predicate(domain: String, userID: String, blockedDomain: String) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            DomainBlock.predicate(domain: domain),
            DomainBlock.predicate(userID: userID),
            DomainBlock.predicate(blockedDomain: blockedDomain)
        ])
    }
}
