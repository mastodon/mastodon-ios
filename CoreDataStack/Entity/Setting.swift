//
//  Setting.swift
//  CoreDataStack
//
//  Created by ihugo on 2021/4/9.
//

import CoreData
import Foundation

@objc(Setting)
public final class Setting: NSManagedObject {
    @NSManaged public var appearance: String?
    @NSManaged public var triggerBy: String?
    @NSManaged public var domain: String?
    
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

        public init(appearance: String, triggerBy: String, domain: String) {
            self.appearance = appearance
            self.triggerBy = triggerBy
            self.domain = domain
        }
    }
}

extension Setting: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Setting.createdAt, ascending: false)]
    }
}

extension Setting {
    public static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Setting.domain), domain)
    }
    
}
