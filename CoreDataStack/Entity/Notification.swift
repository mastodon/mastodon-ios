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
    @NSManaged public private(set) var createAt: Date
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var typeRaw: String
    @NSManaged public private(set) var account: MastodonUser
    @NSManaged public private(set) var status: Status?

    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var userID: String
}

extension MastodonNotification {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(MastodonNotification.identifier))
    }
}

public extension MastodonNotification {
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        domain: String,
        userID: String,
        networkDate: Date,
        property: Property
    ) -> MastodonNotification {
        let notification: MastodonNotification = context.insertObject()
        notification.id = property.id
        notification.createAt = property.createdAt
        notification.updatedAt = networkDate
        notification.typeRaw = property.typeRaw
        notification.account = property.account
        notification.status = property.status
        notification.domain = domain
        notification.userID = userID
        return notification
    }
}

public extension MastodonNotification {
    struct Property {
        public init(id: String,
                    typeRaw: String,
                    account: MastodonUser,
                    status: Status?,
                    createdAt: Date
        ) {
            self.id = id
            self.typeRaw = typeRaw
            self.account = account
            self.status = status
            self.createdAt = createdAt
        }
        
        public let id: String
        public let typeRaw: String
        public let account: MastodonUser
        public let status: Status?
        public let createdAt: Date
    }
}

extension MastodonNotification {
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.domain), domain)
    }
    
    static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.userID), userID)
    }
    
    static func predicate(typeRaw: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonNotification.typeRaw), typeRaw)
    }
    
    public static func predicate(domain: String, userID: String, typeRaw: String? = nil) -> NSPredicate {
        if let typeRaw = typeRaw {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                MastodonNotification.predicate(domain: domain),
                MastodonNotification.predicate(typeRaw: typeRaw),
                MastodonNotification.predicate(userID: userID),
            ])
        } else {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                MastodonNotification.predicate(domain: domain),
                MastodonNotification.predicate(userID: userID)
            ])
        }
    }
    
    public static func predicate(validTypesRaws types: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonNotification.typeRaw), types)
    }

}

extension MastodonNotification: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonNotification.createAt, ascending: false)]
    }
}
