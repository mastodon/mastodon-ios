//
//  SettingNotification+CoreDataClass.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//
//

import Foundation
import CoreData

@objc(Subscription)
public final class Subscription: NSManagedObject {
    @NSManaged public var id: String
    @NSManaged public var endpoint: String
    @NSManaged public var serverKey: String
    
    /// four types:
    /// - anyone
    /// - a follower
    /// - anyone I follow
    /// - no one
    @NSManaged public var type: String
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // MARK: - relationships
    @NSManaged public var alert: SubscriptionAlerts?
    // MARK: holder
    @NSManaged public var setting: Setting?
}

public extension Subscription {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: #keyPath(Subscription.createdAt))
    }
    
    func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Subscription {
        let setting: Subscription = context.insertObject()
        setting.id = property.id
        setting.endpoint = property.endpoint
        setting.serverKey = property.serverKey
        
        return setting
    }
}

public extension Subscription {
    struct Property {
        public let endpoint: String
        public let id: String
        public let serverKey: String
        public let type: String

        public init(endpoint: String, id: String, serverKey: String, type: String) {
            self.endpoint = endpoint
            self.id = id
            self.serverKey = serverKey
            self.type = type
        }
    }
    
    func updateIfNeed(property: Property) {
        if self.endpoint != property.endpoint {
            self.endpoint = property.endpoint
        }
        if self.id != property.id {
            self.id = property.id
        }
        if self.serverKey != property.serverKey {
            self.serverKey = property.serverKey
        }
        if self.type != property.type {
            self.type = property.type
        }
    }
}

extension Subscription: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Subscription.createdAt, ascending: false)]
    }
}

extension Subscription {
    
    public static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Subscription.id), id)
    }
    
}
