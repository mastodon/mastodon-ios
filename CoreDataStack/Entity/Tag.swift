//
//  Tag.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class Tag: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var createAt: Date
    @NSManaged public private(set) var updatedAt: Date

    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var url: String

    // one-to-one relationship
    @NSManaged public private(set) var searchHistory: SearchHistory?

    // many-to-many relationship
    @NSManaged public private(set) var statuses: Set<Status>?

    // one-to-many relationship
    @NSManaged public private(set) var histories: Set<History>?
}

public extension Tag {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(Tag.identifier))
        setPrimitiveValue(Date(), forKey: #keyPath(Tag.createAt))
        setPrimitiveValue(Date(), forKey: #keyPath(Tag.updatedAt))
    }

    override func willSave() {
        super.willSave()
        setPrimitiveValue(Date(), forKey: #keyPath(Tag.updatedAt))
    }

    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Tag {
        let tag: Tag = context.insertObject()
        tag.name = property.name
        tag.url = property.url
        if let histories = property.histories {
            tag.mutableSetValue(forKey: #keyPath(Tag.histories)).addObjects(from: histories)
        }
        return tag
    }
}

public extension Tag {
    struct Property {
        public let name: String
        public let url: String
        public let histories: [History]?

        public init(name: String, url: String, histories: [History]?) {
            self.name = name
            self.url = url
            self.histories = histories
        }
    }
}

public extension Tag {
    func updateHistory(index: Int, day: Date, uses: String, account: String) {
        guard let histories = self.histories?.sorted(by: {
            $0.createAt.compare($1.createAt) == .orderedAscending
        }) else { return }
        let history = histories[index]
        history.update(day: day)
        history.update(uses: uses)
        history.update(accounts: account)
    }
    
    func appendHistory(history: History) {
        self.mutableSetValue(forKeyPath: #keyPath(Tag.histories)).add(history)
    }
    
    func update(url: String) {
        if self.url != url {
            self.url = url
        }
    }
}

extension Tag: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \Tag.createAt, ascending: false)]
    }
}

public extension Tag {
    static func predicate(name: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(Tag.name), name)
    }
}
