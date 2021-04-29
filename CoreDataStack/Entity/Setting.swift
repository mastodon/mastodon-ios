//
//  Setting.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//

import CoreData
import Foundation

public final class Setting: NSManagedObject {
    
    @NSManaged public var appearanceRaw: String
    @NSManaged public var domain: String
    @NSManaged public var userID: String
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
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
        setting.appearanceRaw = property.appearanceRaw
        setting.domain = property.domain
        setting.userID = property.userID
        return setting
    }
    
    public func update(appearanceRaw: String) {
        guard appearanceRaw != self.appearanceRaw else { return }
        self.appearanceRaw = appearanceRaw
        didUpdate(at: Date())
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension Setting {
    public struct Property {
        public let domain: String
        public let userID: String
        public let appearanceRaw: String

        public init(domain: String, userID: String, appearanceRaw: String) {
            self.domain = domain
            self.userID = userID
            self.appearanceRaw = appearanceRaw
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
