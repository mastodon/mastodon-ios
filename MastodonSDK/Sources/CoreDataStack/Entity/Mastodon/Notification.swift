//
//  Notification.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/4/13.
//

import Foundation
import CoreData

public final class Notification: NSManagedObject {
    public typealias ID = String

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var typeRaw: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var userID: String

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var account: MastodonUser
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var status: Status?
    
    // many-to-one relationship
    @NSManaged public private(set) var feeds: Set<Feed>

}

extension Notification {
    // sourcery: autoUpdatableObject
    @objc public var followRequestState: MastodonFollowRequestState {
        get {
            let keyPath = #keyPath(Notification.followRequestState)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data, !data.isEmpty else { return .init(state: .none) }
                let state = try JSONDecoder().decode(MastodonFollowRequestState.self, from: data)
                return state
            } catch {
                assertionFailure(error.localizedDescription)
                return .init(state: .none)
            }
        }
        set {
            let keyPath = #keyPath(Notification.followRequestState)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject
    @objc public var transientFollowRequestState: MastodonFollowRequestState {
        get {
            let keyPath = #keyPath(Notification.transientFollowRequestState)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return .init(state: .none) }
                let state = try JSONDecoder().decode(MastodonFollowRequestState.self, from: data)
                return state
            } catch {
                assertionFailure(error.localizedDescription)
                return .init(state: .none)
            }
        }
        set {
            let keyPath = #keyPath(Notification.transientFollowRequestState)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
}

extension Notification: FeedIndexable { }

extension Notification {
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> Notification {
        let object: Notification = context.insertObject()
        
        object.configure(property: property)
        object.configure(relationship: relationship)
        
        return object
    }
}

extension Notification: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Notification.createAt, ascending: false)]
    }
}

extension Notification {
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Notification.domain), domain)
    }
    
    static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Notification.userID), userID)
    }
    
    static func predicate(id: ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Notification.id), id)
    }
    
    static func predicate(typeRaw: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Notification.typeRaw), typeRaw)
    }
    
    public static func predicate(
        domain: String,
        userID: String,
        id: ID
    ) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            Notification.predicate(domain: domain),
            Notification.predicate(userID: userID),
            Notification.predicate(id: id)
        ])
    }
    
    public static func predicate(
        domain: String,
        userID: String,
        typeRaw: String? = nil
    ) -> NSPredicate {
        if let typeRaw = typeRaw {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                Notification.predicate(domain: domain),
                Notification.predicate(typeRaw: typeRaw),
                Notification.predicate(userID: userID),
            ])
        } else {
            return NSCompoundPredicate(andPredicateWithSubpredicates: [
                Notification.predicate(domain: domain),
                Notification.predicate(userID: userID)
            ])
        }
    }
    
    public static func predicate(validTypesRaws types: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(Notification.typeRaw), types)
    }

}

// MARK: - AutoGenerateProperty
extension Notification: AutoGenerateProperty {
    // sourcery:inline:Notification.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let id: ID
        public let typeRaw: String
        public let domain: String
        public let userID: String
        public let createAt: Date
        public let updatedAt: Date

    	public init(
    		id: ID,
    		typeRaw: String,
    		domain: String,
    		userID: String,
    		createAt: Date,
    		updatedAt: Date
    	) {
    		self.id = id
    		self.typeRaw = typeRaw
    		self.domain = domain
    		self.userID = userID
    		self.createAt = createAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.id = property.id
    	self.typeRaw = property.typeRaw
    	self.domain = property.domain
    	self.userID = property.userID
    	self.createAt = property.createAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension Notification: AutoGenerateRelationship {
    // sourcery:inline:Notification.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let account: MastodonUser
    	public let status: Status?

    	public init(
    		account: MastodonUser,
    		status: Status?
    	) {
    		self.account = account
    		self.status = status
    	}
    }

    public func configure(relationship: Relationship) {
    	self.account = relationship.account
    	self.status = relationship.status
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension Notification: AutoUpdatableObject {
    // sourcery:inline:Notification.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(followRequestState: MastodonFollowRequestState) {
    	if self.followRequestState != followRequestState {
    		self.followRequestState = followRequestState
    	}
    }
    public func update(transientFollowRequestState: MastodonFollowRequestState) {
    	if self.transientFollowRequestState != transientFollowRequestState {
    		self.transientFollowRequestState = transientFollowRequestState
    	}
    }
    // sourcery:end
}

extension Notification {
    public func attach(feed: Feed) {
        mutableSetValue(forKey: #keyPath(Notification.feeds)).add(feed)
    }
}
