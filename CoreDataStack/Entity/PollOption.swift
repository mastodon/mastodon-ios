//
//  PollOption.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021-3-2.
//

import Foundation
import CoreData

public final class PollOption: NSManagedObject {
    @NSManaged public private(set) var index: NSNumber
    @NSManaged public private(set) var title: String
    @NSManaged public private(set) var votesCount: NSNumber?
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // many-to-one relationship
    @NSManaged public private(set) var poll: Poll
    
    // many-to-many relationship
    @NSManaged public private(set) var votedBy: Set<MastodonUser>?
}

extension PollOption {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        createdAt = Date()
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        votedBy: MastodonUser?
    ) -> PollOption {
        let option: PollOption = context.insertObject()
        
        option.index = property.index
        option.title = property.title
        option.votesCount = property.votesCount
        option.updatedAt = property.networkDate
        
        if let votedBy = votedBy {
            option.mutableSetValue(forKey: #keyPath(PollOption.votedBy)).add(votedBy)
        }
        
        return option
    }
    
    public func update(votesCount: Int?) {
        if self.votesCount?.intValue != votesCount {
            self.votesCount = votesCount.flatMap { NSNumber(value: $0) }
        }
    }
    
    public func update(voted: Bool, by: MastodonUser) {
        if voted {
            if !(self.votedBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(PollOption.votedBy)).add(by)
            }
        } else {
            if !(self.votedBy ?? Set()).contains(by) {
                self.mutableSetValue(forKey: #keyPath(PollOption.votedBy)).remove(by)
            }
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension PollOption {
    public struct Property {
        public let index: NSNumber
        public let title: String
        public let votesCount: NSNumber?
        
        public let networkDate: Date

        public init(index: Int, title: String, votesCount: Int?, networkDate: Date) {
            self.index = NSNumber(value: index)
            self.title = title
            self.votesCount = votesCount.flatMap { NSNumber(value: $0) }
            self.networkDate = networkDate
        }
    }
}

extension PollOption: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \PollOption.createdAt, ascending: false)]
    }
}
