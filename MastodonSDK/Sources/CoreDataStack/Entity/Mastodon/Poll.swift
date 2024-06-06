//
//  Poll.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import Foundation
import CoreData

public final class PollLegacy: NSManagedObject {
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var expiresAt: Date?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var expired: Bool
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var multiple: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var votesCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var votersCount: Int64
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isVoting: Bool
    
    // one-to-one relationship
    @NSManaged public private(set) var status: Status?

    // many-to-many relationship
    @NSManaged public private(set) var votedBy: Set<MastodonUser>?
}

extension PollLegacy {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> PollLegacy {
        let object: PollLegacy = context.insertObject()
        
        object.configure(property: property)
        
        return object
    }
    
}

extension PollLegacy: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \PollLegacy.createdAt, ascending: false)]
    }
}

extension PollLegacy {
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(PollLegacy.domain), domain)
    }
    
    static func predicate(id: ID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(PollLegacy.id), id)
    }

    static func predicate(ids: [ID]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(PollLegacy.id), ids)
    }
    
    public static func predicate(domain: String, id: ID) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(id: id)
        ])
    }
    
    public static func predicate(domain: String, ids: [ID]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(ids: ids)
        ])
    }
}

//extension Poll {
//
//    public override func awakeFromInsert() {
//        super.awakeFromInsert()
//        setPrimitiveValue(Date(), forKey: #keyPath(Poll.createdAt))
//    }
//
//    @discardableResult
//    public static func insert(
//        into context: NSManagedObjectContext,
//        property: Property,
//        votedBy: MastodonUser?,
//        options: [PollOption]
//    ) -> Poll {
//        let poll: Poll = context.insertObject()
//
//        poll.id = property.id
//        poll.expiresAt = property.expiresAt
//        poll.expired = property.expired
//        poll.multiple = property.multiple
//        poll.votesCount = property.votesCount
//        poll.votersCount = property.votersCount
//
//
//        poll.updatedAt = property.networkDate
//
//        if let votedBy = votedBy {
//            poll.mutableSetValue(forKey: #keyPath(Poll.votedBy)).add(votedBy)
//        }
//        poll.mutableSetValue(forKey: #keyPath(Poll.options)).addObjects(from: options)
//
//        return poll
//    }
//
//    public func update(expiresAt: Date?) {
//        if self.expiresAt != expiresAt {
//            self.expiresAt = expiresAt
//        }
//    }
//
//    public func update(expired: Bool) {
//        if self.expired != expired {
//            self.expired = expired
//        }
//    }
//
//    public func update(votesCount: Int) {
//        if self.votesCount.intValue != votesCount {
//            self.votesCount = NSNumber(value: votesCount)
//        }
//    }
//
//    public func update(votersCount: Int?) {
//        if self.votersCount?.intValue != votersCount {
//            self.votersCount = votersCount.flatMap { NSNumber(value: $0) }
//        }
//    }
//
//    public func update(voted: Bool, by: MastodonUser) {
//        if voted {
//            if !(votedBy ?? Set()).contains(by) {
//                mutableSetValue(forKey: #keyPath(Poll.votedBy)).add(by)
//            }
//        } else {
//            if (votedBy ?? Set()).contains(by) {
//                mutableSetValue(forKey: #keyPath(Poll.votedBy)).remove(by)
//            }
//        }
//    }
//
//    public func didUpdate(at networkDate: Date) {
//        self.updatedAt = networkDate
//    }
//
//}

//extension Poll {
//    public struct Property {
//        public let id: ID
//        public let expiresAt: Date?
//        public let expired: Bool
//        public let multiple: Bool
//        public let votesCount: NSNumber
//        public let votersCount: NSNumber?
//
//        public let networkDate: Date
//
//        public init(
//            id: Poll.ID,
//            expiresAt: Date?,
//            expired: Bool,
//            multiple: Bool,
//            votesCount: Int,
//            votersCount: Int?,
//            networkDate: Date
//        ) {
//            self.id = id
//            self.expiresAt = expiresAt
//            self.expired = expired
//            self.multiple = multiple
//            self.votesCount = NSNumber(value: votesCount)
//            self.votersCount = votersCount.flatMap { NSNumber(value: $0) }
//            self.networkDate = networkDate
//        }
//    }
//}

// MARK: - AutoGenerateProperty
extension PollLegacy: AutoGenerateProperty {
    // sourcery:inline:Poll.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let domain: String
        public let id: ID
        public let expiresAt: Date?
        public let expired: Bool
        public let multiple: Bool
        public let votesCount: Int64
        public let votersCount: Int64
        public let createdAt: Date
        public let updatedAt: Date

    	public init(
    		domain: String,
    		id: ID,
    		expiresAt: Date?,
    		expired: Bool,
    		multiple: Bool,
    		votesCount: Int64,
    		votersCount: Int64,
    		createdAt: Date,
    		updatedAt: Date
    	) {
    		self.domain = domain
    		self.id = id
    		self.expiresAt = expiresAt
    		self.expired = expired
    		self.multiple = multiple
    		self.votesCount = votesCount
    		self.votersCount = votersCount
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    	}
    }

    public func configure(property: Property) {
    	self.domain = property.domain
    	self.id = property.id
    	self.expiresAt = property.expiresAt
    	self.expired = property.expired
    	self.multiple = property.multiple
    	self.votesCount = property.votesCount
    	self.votersCount = property.votersCount
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    }

    public func update(property: Property) {
    	update(expiresAt: property.expiresAt)
    	update(expired: property.expired)
    	update(votesCount: property.votesCount)
    	update(votersCount: property.votersCount)
    	update(updatedAt: property.updatedAt)
    }
    // sourcery:end

}

// MARK: - AutoUpdatableObject
extension PollLegacy: AutoUpdatableObject {
    // sourcery:inline:Poll.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(expiresAt: Date?) {
    	if self.expiresAt != expiresAt {
    		self.expiresAt = expiresAt
    	}
    }
    public func update(expired: Bool) {
    	if self.expired != expired {
    		self.expired = expired
    	}
    }
    public func update(votesCount: Int64) {
    	if self.votesCount != votesCount {
    		self.votesCount = votesCount
    	}
    }
    public func update(votersCount: Int64) {
    	if self.votersCount != votersCount {
    		self.votersCount = votersCount
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(isVoting: Bool) {
    	if self.isVoting != isVoting {
    		self.isVoting = isVoting
    	}
    }
    // sourcery:end
    
    public func update(voted: Bool, by: MastodonUser) {
        if voted {
            if !(votedBy ?? Set()).contains(by) {
                mutableSetValue(forKey: #keyPath(PollLegacy.votedBy)).add(by)
            }
        } else {
            if (votedBy ?? Set()).contains(by) {
                mutableSetValue(forKey: #keyPath(PollLegacy.votedBy)).remove(by)
            }
        }
    }
}
