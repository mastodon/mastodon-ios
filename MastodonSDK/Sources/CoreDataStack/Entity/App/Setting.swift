//
//  Setting.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//

import CoreData
import Foundation

public final class Setting: NSManagedObject {
    
    @NSManaged public var domain: String
    @NSManaged public var userID: String

    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    @NSManaged private var rawRecentLanguages: Data?
    @objc dynamic public var recentLanguages: [String] {
        get {
            if let data = rawRecentLanguages, let result = try? JSONDecoder().decode([String].self, from: data) {
                return result
            }
            return []
        }
        set {
            rawRecentLanguages = try? JSONEncoder().encode(Array(newValue.prefix(3)))
        }
    }
    
    // one-to-many relationships
    @NSManaged public var subscriptions: Set<Subscription>?
}

extension Setting {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(Setting.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(Setting.updatedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Setting {
        let setting: Setting = context.insertObject()
        setting.domain = property.domain
        setting.userID = property.userID
        return setting
    }

    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
}

extension Setting {
    public struct Property {
        public let domain: String
        public let userID: String

        public init(
            domain: String,
            userID: String
        ) {
            self.domain = domain
            self.userID = userID
        }
    }
}

extension Setting: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Setting.createdAt, ascending: false)]
    }
}

extension Setting {
    public static func predicate(domain: String, userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@ AND %K == %@",
                           #keyPath(Setting.domain), domain,
                           #keyPath(Setting.userID), userID
        )
    }

}

extension Setting {
    public var activeSubscription: Subscription? {
        return (subscriptions ?? Set())
            .sorted(by: { $0.activedAt > $1.activedAt })
            .first
    }
}
