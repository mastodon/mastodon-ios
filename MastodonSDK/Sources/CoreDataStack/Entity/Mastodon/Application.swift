//
//  Application.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/3.
//

import CoreData
import Foundation

public final class Application: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var createAt: Date

    @NSManaged public private(set) var name: String
    @NSManaged public private(set) var website: String?
    @NSManaged public private(set) var vapidKey: String?

    // one-to-one relationship
    @NSManaged public private(set) var status: Status
}

public extension Application {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(Application.identifier))
    }

    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Application {
        let app: Application = context.insertObject()
        app.name = property.name
        app.website = property.website
        app.vapidKey = property.vapidKey
        return app
    }
}

public extension Application {
    struct Property {
        public let name: String
        public let website: String?
        public let vapidKey: String?

        public init(name: String, website: String?, vapidKey: String?) {
            self.name = name
            self.website = website
            self.vapidKey = vapidKey
        }
    }
}

extension Application: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Application.createAt, ascending: false)]
    }
}
