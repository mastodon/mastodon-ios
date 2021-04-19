//
//  Setting.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//

import CoreData
import Foundation

public final class Setting: NSManagedObject {
    @NSManaged public var appearance: String?
    @NSManaged public var triggerBy: String?
    @NSManaged public var domain: String?
    @NSManaged public var userID: String?
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // relationships
    @NSManaged public var subscription: Set<Subscription>?
}

public extension Setting {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: #keyPath(Setting.createdAt))
    }
    
    func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Setting {
        let setting: Setting = context.insertObject()
        setting.appearance = property.appearance
        setting.triggerBy = property.triggerBy
        setting.domain = property.domain
        setting.userID = property.userID
        return setting
    }
    
    func update(appearance: String?) {
        guard appearance != self.appearance else { return }
        self.appearance = appearance
        didUpdate(at: Date())
    }
    
    func update(triggerBy: String?) {
        guard triggerBy != self.triggerBy else { return }
        self.triggerBy = triggerBy
        didUpdate(at: Date())
    }
}

public extension Setting {
    struct Property {
        public let appearance: String
        public let triggerBy: String
        public let domain: String
        public let userID: String

        public init(appearance: String, triggerBy: String, domain: String, userID: String) {
            self.appearance = appearance
            self.triggerBy = triggerBy
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
