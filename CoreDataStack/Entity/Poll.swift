//
//  Poll.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import Foundation
import CoreData

public final class Poll: NSManagedObject {
    public typealias ID = String
    
    @NSManaged public private(set) var id: ID
    @NSManaged public private(set) var expiresAt: Date?
    @NSManaged public private(set) var expired: Bool
    @NSManaged public private(set) var multiple: Bool
    @NSManaged public private(set) var votesCount: NSNumber
    @NSManaged public private(set) var votersCount: NSNumber?
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var toot: Toot
    
    // one-to-many relationship
    @NSManaged public private(set) var options: Set<PollOption>
}

extension Poll {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        options: [PollOption]
    ) -> Poll {
        let poll: Poll = context.insertObject()
        
        poll.id = property.id
        poll.expiresAt = property.expiresAt
        poll.expired = property.expired
        poll.multiple = property.multiple
        poll.votesCount = property.votesCount
        poll.votersCount = property.votersCount
        
        poll.updatedAt = property.networkDate
        poll.mutableSetValue(forKey: #keyPath(Poll.options)).addObjects(from: options)
        
        return poll
    }
    
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
    
    public func update(votesCount: Int) {
        if self.votesCount.intValue != votesCount {
            self.votesCount = NSNumber(value: votesCount)
        }
    }
    
    public func update(votersCount: Int?) {
        if self.votersCount?.intValue != votersCount {
            self.votersCount = votersCount.flatMap { NSNumber(value: $0) }
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension Poll {
    public struct Property {
        public let id: ID
        public let expiresAt: Date?
        public let expired: Bool
        public let multiple: Bool
        public let votesCount: NSNumber
        public let votersCount: NSNumber?
        
        public let networkDate: Date

        public init(
            id: Poll.ID,
            expiresAt: Date?,
            expired: Bool,
            multiple: Bool,
            votesCount: Int,
            votersCount: Int?,
            networkDate: Date
        ) {
            self.id = id
            self.expiresAt = expiresAt
            self.expired = expired
            self.multiple = multiple
            self.votesCount = NSNumber(value: votesCount)
            self.votersCount = votersCount.flatMap { NSNumber(value: $0) }
            self.networkDate = networkDate
        }
    }
}

extension Poll: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Poll.createdAt, ascending: false)]
    }
}
