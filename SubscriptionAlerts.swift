//
//  PushSubscriptionAlerts+CoreDataClass.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//
//

import Foundation
import CoreData

@objc(SubscriptionAlerts)
public final class SubscriptionAlerts: NSManagedObject {
    @NSManaged public var follow: Bool
    @NSManaged public var favourite: Bool
    @NSManaged public var reblog: Bool
    @NSManaged public var mention: Bool
    @NSManaged public var poll: Bool
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // MARK: - relationships
    @NSManaged public var pushSubscription: Subscription?
}

public extension SubscriptionAlerts {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: #keyPath(SubscriptionAlerts.createdAt))
    }
    
    func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> SubscriptionAlerts {
        let alerts: SubscriptionAlerts = context.insertObject()
        alerts.favourite = property.favourite
        alerts.follow = property.follow
        alerts.mention = property.mention
        alerts.poll = property.poll
        alerts.reblog = property.reblog
        return alerts
    }
    
    func update(favourite: Bool) {
        guard self.favourite != favourite else { return }
        self.favourite = favourite
        
        didUpdate(at: Date())
    }
    
    func update(follow: Bool) {
        guard self.follow != follow else { return }
        self.follow = follow
        
        didUpdate(at: Date())
    }
    
    func update(mention: Bool) {
        guard self.mention != mention else { return }
        self.mention = mention
        
        didUpdate(at: Date())
    }
    
    func update(poll: Bool) {
        guard self.poll != poll else { return }
        self.poll = poll
        
        didUpdate(at: Date())
    }
    
    func update(reblog: Bool) {
        guard self.reblog != reblog else { return }
        self.reblog = reblog
        
        didUpdate(at: Date())
    }
}

public extension SubscriptionAlerts {
    struct Property {
        public let favourite: Bool
        public let follow: Bool
        public let mention: Bool
        public let poll: Bool
        public let reblog: Bool

        public init(favourite: Bool?, follow: Bool?, mention: Bool?, poll: Bool?, reblog: Bool?) {
            self.favourite = favourite ?? true
            self.follow = follow ?? true
            self.mention = mention ?? true
            self.poll = poll ?? true
            self.reblog = reblog ?? true
        }
    }
    
    func updateIfNeed(property: Property) {
        if self.follow != property.follow {
            self.follow = property.follow
        }
        
        if self.favourite != property.favourite {
            self.favourite = property.favourite
        }
        
        if self.reblog != property.reblog {
            self.reblog = property.reblog
        }
        
        if self.mention != property.mention {
            self.mention = property.mention
        }
        
        if self.poll != property.poll {
            self.poll = property.poll
        }
    }
}

extension SubscriptionAlerts: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \SubscriptionAlerts.createdAt, ascending: false)]
    }
}
