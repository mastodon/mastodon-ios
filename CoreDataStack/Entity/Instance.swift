//
//  Instance.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import Foundation
import CoreData

public final class Instance: NSManagedObject {
    @NSManaged public var domain: String
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date

    @NSManaged public private(set) var configurationRaw: Data?
    
    // MARK: one-to-many relationships
    @NSManaged public var authentications: Set<MastodonAuthentication>
}

extension Instance {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(Instance.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(Instance.updatedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Instance {
        let instance: Instance = context.insertObject()
        instance.domain = property.domain
        return instance
    }
    
    public func update(configurationRaw: Data?) {
        self.configurationRaw = configurationRaw
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
}

extension Instance {
    public struct Property {
        public let domain: String
        
        public init(domain: String) {
            self.domain = domain
        }
    }
}

extension Instance: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Instance.createdAt, ascending: false)]
    }
}

extension Instance {
    public static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Instance.domain), domain)
    }
}
