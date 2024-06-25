//
//  Instance.swift
//  CoreDataStack
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import Foundation
import CoreData

@available(*, deprecated, message: "Please use `MastodonAuthentication.InstanceConfiguration` instead.")
public final class Instance: NSManagedObject {
    @NSManaged public var domain: String
    @NSManaged public var version: String?

    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date

    @NSManaged public private(set) var configurationRaw: Data?
    @NSManaged public private(set) var configurationV2Raw: Data?

    // MARK: one-to-many relationships
    @NSManaged public var authentications: Set<MastodonAuthenticationLegacy>
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
        instance.version = property.version
        return instance
    }
    
    public func update(configurationRaw: Data?) {
        self.configurationRaw = configurationRaw
    }
    
    public func update(configurationV2Raw: Data?) {
        self.configurationV2Raw = configurationV2Raw
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
}

extension Instance {
    public struct Property {
        public let domain: String
        public let version: String?

        public init(domain: String, version: String?) {
            self.domain = domain
            self.version = version
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
