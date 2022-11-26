//
//  ManagedObjectRecord.swift
//  ManagedObjectRecord
//
//  Created by Cirno MainasuK on 2021-8-25.
//  Copyright © 2021 Twidere. All rights reserved.
//

import Foundation
import CoreData

public class ManagedObjectRecord<T: NSFetchRequestResult>: Hashable {
    
    public let objectID: NSManagedObjectID
    
    public init(objectID: NSManagedObjectID) {
        self.objectID = objectID
    }
    
    public func object(in managedObjectContext: NSManagedObjectContext) -> T? {
        return managedObjectContext.object(with: objectID) as? T
    }
    
    public static func == (lhs: ManagedObjectRecord<T>, rhs: ManagedObjectRecord<T>) -> Bool {
        return lhs.objectID == rhs.objectID
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
    
}

extension Managed where Self: NSManagedObject {
    public var asRecord: ManagedObjectRecord<Self> {
        return .init(objectID: objectID)
    }
}
