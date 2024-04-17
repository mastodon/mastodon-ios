//
//  PollOption.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import Foundation
import CoreData

public final class PollOptionLegacy: NSManagedObject {
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var index: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var title: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var votesCount: Int64
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isSelected: Bool
    
    // many-to-one relationship
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var poll: PollLegacy?
    
    // many-to-many relationship
    @NSManaged public private(set) var votedBy: Set<MastodonUser>?
}


extension PollOptionLegacy {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> PollOptionLegacy {
        let object: PollOptionLegacy = context.insertObject()
        
        object.configure(property: property)
        
        return object
    }
    
}

extension PollOptionLegacy: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \PollOptionLegacy.createdAt, ascending: false)]
    }
}

//extension PollOption {
//
//    public override func awakeFromInsert() {
//        super.awakeFromInsert()
//        setPrimitiveValue(Date(), forKey: #keyPath(PollOption.createdAt))
//    }
//
//    @discardableResult
//    public static func insert(
//        into context: NSManagedObjectContext,
//        property: Property,
//        votedBy: MastodonUser?
//    ) -> PollOption {
//        let option: PollOption = context.insertObject()
//
//        option.index = property.index
//        option.title = property.title
//        option.votesCount = property.votesCount
//        option.updatedAt = property.networkDate
//
//        if let votedBy = votedBy {
//            option.mutableSetValue(forKey: #keyPath(PollOption.votedBy)).add(votedBy)
//        }
//
//        return option
//    }
//
//    public func update(votesCount: Int?) {
//        if self.votesCount?.intValue != votesCount {
//            self.votesCount = votesCount.flatMap { NSNumber(value: $0) }
//        }
//    }
//
//    public func didUpdate(at networkDate: Date) {
//        self.updatedAt = networkDate
//    }
//
//}

//extension PollOption {
//    public struct Property {
//        public let index: NSNumber
//        public let title: String
//        public let votesCount: NSNumber?
//
//        public let networkDate: Date
//
//        public init(index: Int, title: String, votesCount: Int?, networkDate: Date) {
//            self.index = NSNumber(value: index)
//            self.title = title
//            self.votesCount = votesCount.flatMap { NSNumber(value: $0) }
//            self.networkDate = networkDate
//        }
//    }
//}
//

// MARK: - AutoGenerateProperty
extension PollOptionLegacy: AutoGenerateProperty {
    // sourcery:inline:PollOption.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let index: Int64
        public let title: String
        public let votesCount: Int64
        public let createdAt: Date
        public let updatedAt: Date
        public let poll: PollLegacy?

    	public init(
    		index: Int64,
    		title: String,
    		votesCount: Int64,
    		createdAt: Date,
    		updatedAt: Date,
    		poll: PollLegacy?
    	) {
    		self.index = index
    		self.title = title
    		self.votesCount = votesCount
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    		self.poll = poll
    	}
    }

    public func configure(property: Property) {
    	self.index = property.index
    	self.title = property.title
    	self.votesCount = property.votesCount
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    	self.poll = property.poll
    }

    public func update(property: Property) {
    	update(title: property.title)
    	update(votesCount: property.votesCount)
    	update(updatedAt: property.updatedAt)
    	update(poll: property.poll)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension PollOptionLegacy: AutoUpdatableObject {
    // sourcery:inline:PollOption.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(title: String) {
    	if self.title != title {
    		self.title = title
    	}
    }
    public func update(votesCount: Int64) {
    	if self.votesCount != votesCount {
    		self.votesCount = votesCount
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(isSelected: Bool) {
    	if self.isSelected != isSelected {
    		self.isSelected = isSelected
    	}
    }
    public func update(poll: PollLegacy?) {
    	if self.poll != poll {
    		self.poll = poll
    	}
    }
    // sourcery:end
    
    public func update(voted: Bool, by: MastodonUser) {
        if voted {
            if !(self.votedBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(PollOptionLegacy.votedBy)).add(by)
            }
        } else {
            if (self.votedBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(PollOptionLegacy.votedBy)).remove(by)
            }
        }
    }
}
