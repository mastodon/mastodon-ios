//
//  SettingNotification+CoreDataClass.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//
//

import Foundation
import CoreData

public final class Subscription: NSManagedObject {
    
    @NSManaged public var id: String?
    @NSManaged public var endpoint: String?
    @NSManaged public var policyRaw: String
    @NSManaged public var serverKey: String?
    @NSManaged public var userToken: String?
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var activedAt: Date

    // MARK: one-to-one relationships
    @NSManaged public var alert: SubscriptionAlerts
    
    // MARK: many-to-one relationships
    @NSManaged public var setting: Setting?
}

public extension Subscription {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(Subscription.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(Subscription.updatedAt))
        setPrimitiveValue(now, forKey: #keyPath(Subscription.activedAt))
    }
    
    func update(activedAt: Date) {
        self.activedAt = activedAt
    }
    
    func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        setting: Setting
    ) -> Subscription {
        let subscription: Subscription = context.insertObject()
        subscription.policyRaw = property.policyRaw
        subscription.setting = setting
        return subscription
    }
}

public extension Subscription {
    struct Property {
        public let policyRaw: String

        public init(policyRaw: String) {
            self.policyRaw = policyRaw
        }
    }
}

extension Subscription: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Subscription.createdAt, ascending: false)]
    }
}

extension Subscription {
    
    public static func predicate(policyRaw: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Subscription.policyRaw), policyRaw)
    }
    
    public static func predicate(userToken: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Subscription.userToken), userToken)
    }
    
}
