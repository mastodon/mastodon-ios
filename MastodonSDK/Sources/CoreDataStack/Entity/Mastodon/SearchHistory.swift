//
//  SearchHistory.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/4/7.
//

import Foundation
import CoreData

public final class SearchHistory: NSManagedObject {
    public typealias ID = UUID
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var identifier: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var userID: MastodonUser.ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date

    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var account: MastodonUser?
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var hashtag: Tag?
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var status: Status?

}

extension SearchHistory {
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> SearchHistory {
        let object: SearchHistory = context.insertObject()
        
        object.configure(property: property)
        object.configure(relationship: relationship)
        
        return object
    }
}

extension SearchHistory: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \SearchHistory.updatedAt, ascending: false)]
    }
}

extension SearchHistory {
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(SearchHistory.domain), domain)
    }

    static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(SearchHistory.userID), userID)
    }

    public static func predicate(domain: String, userID: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(userID: userID)
        ])
    }
}

// MARK: - AutoGenerateProperty
extension SearchHistory: AutoGenerateProperty {
    // sourcery:inline:SearchHistory.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let identifier: ID
        public let domain: String
        public let userID: MastodonUser.ID
        public let createAt: Date
        public let updatedAt: Date

    	public init(
    		identifier: ID,
    		domain: String,
    		userID: MastodonUser.ID,
    		createAt: Date,
    		updatedAt: Date
    	) {
    		self.identifier = identifier
    		self.domain = domain
    		self.userID = userID
    		self.createAt = createAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.identifier = property.identifier
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
extension SearchHistory: AutoGenerateRelationship {
    // sourcery:inline:SearchHistory.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let account: MastodonUser?
    	public let hashtag: Tag?
    	public let status: Status?

    	public init(
    		account: MastodonUser?,
    		hashtag: Tag?,
    		status: Status?
    	) {
    		self.account = account
    		self.hashtag = hashtag
    		self.status = status
    	}
    }

    public func configure(relationship: Relationship) {
    	self.account = relationship.account
    	self.hashtag = relationship.hashtag
    	self.status = relationship.status
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension SearchHistory: AutoUpdatableObject {
    // sourcery:inline:SearchHistory.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    // sourcery:end
}
