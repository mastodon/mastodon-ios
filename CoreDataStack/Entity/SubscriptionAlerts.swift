//
//  PushSubscriptionAlerts+CoreDataClass.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//
//

import Foundation
import CoreData

public final class SubscriptionAlerts: NSManagedObject {
    @NSManaged public var favouriteRaw: NSNumber?
    @NSManaged public var followRaw: NSNumber?
    @NSManaged public var followRequestRaw: NSNumber?
    @NSManaged public var mentionRaw: NSNumber?
    @NSManaged public var pollRaw: NSNumber?
    @NSManaged public var reblogRaw: NSNumber?
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // MARK: one-to-one relationships
    @NSManaged public var subscription: Subscription
}

extension SubscriptionAlerts {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(SubscriptionAlerts.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(SubscriptionAlerts.updatedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        subscription: Subscription
    ) -> SubscriptionAlerts {
        let alerts: SubscriptionAlerts = context.insertObject()
        
        alerts.favouriteRaw = property.favouriteRaw
        alerts.followRaw = property.followRaw
        alerts.followRequestRaw = property.followRequestRaw
        alerts.mentionRaw = property.mentionRaw
        alerts.pollRaw = property.pollRaw
        alerts.reblogRaw = property.reblogRaw
        
        alerts.subscription = subscription
        
        return alerts
    }
    
    public func update(favourite: Bool?) {
        guard self.favourite != favourite else { return }
        self.favourite = favourite
        
        didUpdate(at: Date())
    }
    
    public func update(follow: Bool?) {
        guard self.follow != follow else { return }
        self.follow = follow
        
        didUpdate(at: Date())
    }
    
    public func update(followRequest: Bool?) {
        guard self.followRequest != followRequest else { return }
        self.followRequest = followRequest
        
        didUpdate(at: Date())
    }
    
    public func update(mention: Bool?) {
        guard self.mention != mention else { return }
        self.mention = mention
        
        didUpdate(at: Date())
    }
    
    public func update(poll: Bool?) {
        guard self.poll != poll else { return }
        self.poll = poll
        
        didUpdate(at: Date())
    }
    
    public func update(reblog: Bool?) {
        guard self.reblog != reblog else { return }
        self.reblog = reblog
        
        didUpdate(at: Date())
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension SubscriptionAlerts {
    
    private func boolean(from number: NSNumber?) -> Bool? {
        return number.flatMap { $0.intValue == 1 }
    }
    
    private func number(from boolean: Bool?) -> NSNumber? {
        return boolean.flatMap { NSNumber(integerLiteral: $0 ? 1 : 0) }
    }
    
    public var favourite: Bool? {
        get { boolean(from: favouriteRaw) }
        set { favouriteRaw = number(from: newValue) }
    }
    
    public var follow: Bool? {
        get { boolean(from: followRaw) }
        set { followRaw = number(from: newValue) }
    }
    
    public var followRequest: Bool? {
        get { boolean(from: followRequestRaw) }
        set { followRequestRaw = number(from: newValue) }
    }
    
    public var mention: Bool? {
        get { boolean(from: mentionRaw) }
        set { mentionRaw = number(from: newValue) }
    }
    
    public var poll: Bool? {
        get { boolean(from: pollRaw) }
        set { pollRaw = number(from: newValue) }
    }
    
    public var reblog: Bool? {
        get { boolean(from: reblogRaw) }
        set { reblogRaw = number(from: newValue) }
    }
    
}

extension SubscriptionAlerts {
    public struct Property {
        public let favouriteRaw: NSNumber?
        public let followRaw: NSNumber?
        public let followRequestRaw: NSNumber?
        public let mentionRaw: NSNumber?
        public let pollRaw: NSNumber?
        public let reblogRaw: NSNumber?

        public init(
            favourite: Bool?,
            follow: Bool?,
            followRequest: Bool?,
            mention: Bool?,
            poll: Bool?,
            reblog: Bool?
        ) {
            self.favouriteRaw = favourite.flatMap { NSNumber(value: $0 ? 1 : 0) }
            self.followRaw = follow.flatMap { NSNumber(value: $0 ? 1 : 0) }
            self.followRequestRaw = followRequest.flatMap { NSNumber(value: $0 ? 1 : 0) }
            self.mentionRaw = mention.flatMap { NSNumber(value: $0 ? 1 : 0) }
            self.pollRaw = poll.flatMap { NSNumber(value: $0 ? 1 : 0) }
            self.reblogRaw = reblog.flatMap { NSNumber(value: $0 ? 1 : 0) }
        }
    }
    
}

extension SubscriptionAlerts: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \SubscriptionAlerts.createdAt, ascending: false)]
    }
}
