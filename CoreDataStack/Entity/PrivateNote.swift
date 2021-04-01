//
//  PrivateNote.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021-4-1.
//

import CoreData
import Foundation

final public class PrivateNote: NSManagedObject {
    
    @NSManaged public private(set) var note: String?
    
    @NSManaged public private(set) var updatedAt: Date
    
    // many-to-one relationship
    @NSManaged public private(set) var to: MastodonUser?
    @NSManaged public private(set) var from: MastodonUser
    
}

extension PrivateNote {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(Date(), forKey: #keyPath(PrivateNote.updatedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> PrivateNote {
        let privateNode: PrivateNote = context.insertObject()
        privateNode.note = property.note
        return privateNode
    }
}

extension PrivateNote {
    public struct Property {
        public let note: String?
        
        init(note: String) {
            self.note = note
        }
    }
    
}

extension PrivateNote: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \PrivateNote.updatedAt, ascending: false)]
    }
}

