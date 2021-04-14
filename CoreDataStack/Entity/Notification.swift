//
//  MastodonNotification.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/4/13.
//

import Foundation
import CoreData

public final class MastodonNotification: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var id: String
    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var createAt: Date
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var type: String
    @NSManaged public private(set) var account: MastodonUser
    @NSManaged public private(set) var status: Status?

}

extension MastodonNotification {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(MastodonNotification.identifier))
    }
    
    public override func willSave() {
        super.willSave()
        setPrimitiveValue(Date(), forKey: #keyPath(MastodonNotification.updatedAt))
    }

}

public extension MastodonNotification {
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        domain: String,
        property: Property
    ) -> MastodonNotification {
        let notification: MastodonNotification = context.insertObject()
        notification.id = property.id
        notification.createAt = property.createdAt
        notification.updatedAt = property.createdAt
        notification.type = property.type
        notification.account = property.account
        notification.status = property.status
        notification.domain = domain
        return notification
    }
}

public extension MastodonNotification {
    struct Property {
        public init(id: String,
                    type: String,
                    account: MastodonUser,
                    status: Status?,
                    createdAt: Date) {
            self.id = id
            self.type = type
            self.account = account
            self.status = status
            self.createdAt = createdAt
        }
        
        public let id: String
        public let type: String
        public let account: MastodonUser
        public let status: Status?
        public let createdAt: Date
    }
}

extension MastodonNotification {
    public static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.domain), domain)
    }
    
    static func predicate(type: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.type), type)
    }
    
    public static func predicate(domain: String, type: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonNotification.predicate(domain: domain),
            MastodonNotification.predicate(type: type)
        ])
    }

}

extension MastodonNotification: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonNotification.createAt, ascending: false)]
    }
}
