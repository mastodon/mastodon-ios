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
    @NSManaged public var follow: NSNumber?
    @NSManaged public var favourite: NSNumber?
    @NSManaged public var reblog: NSNumber?
    @NSManaged public var mention: NSNumber?
    @NSManaged public var poll: NSNumber?
    
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
    
    func update(favourite: NSNumber?) {
        guard self.favourite != favourite else { return }
        self.favourite = favourite
        
        didUpdate(at: Date())
    }
    
    func update(follow: NSNumber?) {
        guard self.follow != follow else { return }
        self.follow = follow
        
        didUpdate(at: Date())
    }
    
    func update(mention: NSNumber?) {
        guard self.mention != mention else { return }
        self.mention = mention
        
        didUpdate(at: Date())
    }
    
    func update(poll: NSNumber?) {
        guard self.poll != poll else { return }
        self.poll = poll
        
        didUpdate(at: Date())
    }
    
    func update(reblog: NSNumber?) {
        guard self.reblog != reblog else { return }
        self.reblog = reblog
        
        didUpdate(at: Date())
    }
}

public extension SubscriptionAlerts {
    struct Property {
        public let favourite: NSNumber?
        public let follow: NSNumber?
        public let mention: NSNumber?
        public let poll: NSNumber?
        public let reblog: NSNumber?

        public init(favourite: NSNumber?, follow: NSNumber?, mention: NSNumber?, poll: NSNumber?, reblog: NSNumber?) {
            self.favourite = favourite
            self.follow = follow
            self.mention = mention
            self.poll = poll
            self.reblog = reblog
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
