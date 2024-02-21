//
//  Feed.swift
//  CoreDataStack
//
//  Created by MainasuK on 2022-1-11.
//

import Foundation
import CoreData

final public class Feed: NSManagedObject {
    
    @NSManaged public private(set) var acctRaw: String
    // sourcery: autoGenerateProperty
    public var acct: Acct {
        get {
            Acct(rawValue: acctRaw) ?? .none
        }
        set {
            acctRaw = newValue.rawValue
        }
    }
    
    @NSManaged public private(set) var kindRaw: String
    // sourcery: autoGenerateProperty
    public var kind: Kind {
        get {
            Kind(rawValue: kindRaw) ?? .none
        }
        set {
            kindRaw = newValue.rawValue
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var hasMore: Bool
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isLoadingMore: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var status: Status?
    @NSManaged public private(set) var notification: Notification?
    
}

extension Feed {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Feed {
        let object: Feed = context.insertObject()
        object.configure(property: property)
        return object
    }
    
}

extension Feed: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Feed.createdAt, ascending: false)]
    }
}

extension Feed {
    
    static func predicate(kind: Kind) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Feed.kindRaw), kind.rawValue)
    }
    
    public static func predicate(acct: Acct) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Feed.acctRaw), acct.rawValue)
    }
    
    public static func predicate(kind: Kind, acct: Acct) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            Feed.predicate(kind: kind),
            Feed.predicate(acct: acct)
        ])
    }
    
    public static func nonePredicate() -> NSPredicate {
        return predicate(kind: .none, acct: .none)
    }
    
    public static func hasMorePredicate() -> NSPredicate {
        return NSPredicate(format: "%K == YES", #keyPath(Feed.hasMore))
    }
    
    public static func hasNotificationPredicate() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(Feed.notification))
    }
}

// MARK: - AutoGenerateProperty
extension Feed: AutoGenerateProperty {
    // sourcery:inline:Feed.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let acct: Acct
        public let kind: Kind
        public let hasMore: Bool
        public let createdAt: Date
        public let updatedAt: Date

    	public init(
    		acct: Acct,
    		kind: Kind,
    		hasMore: Bool,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.acct = acct
    		self.kind = kind
    		self.hasMore = hasMore
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.acct = property.acct
    	self.kind = property.kind
    	self.hasMore = property.hasMore
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(hasMore: property.hasMore)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension Feed: AutoUpdatableObject {
    // sourcery:inline:Feed.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(hasMore: Bool) {
    	if self.hasMore != hasMore {
    		self.hasMore = hasMore
    	}
    }
    public func update(isLoadingMore: Bool) {
    	if self.isLoadingMore != isLoadingMore {
    		self.isLoadingMore = isLoadingMore
    	}
    }
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
}

public protocol FeedIndexable {
    var feeds: Set<Feed> { get }
    func feed(kind: Feed.Kind, acct: Feed.Acct) -> Feed?
}

extension FeedIndexable {
    public func feed(kind: Feed.Kind, acct: Feed.Acct) -> Feed? {
        return feeds.first(where: { feed in
            feed.kind == kind && feed.acct == acct
        })
    }
}
