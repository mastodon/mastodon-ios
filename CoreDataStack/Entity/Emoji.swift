//
//  Emoji.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class Emoji: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var createAt: Date

    @NSManaged public private(set) var shortcode: String
    @NSManaged public private(set) var url: String
    @NSManaged public private(set) var staticURL: String
    @NSManaged public private(set) var visibleInPicker: Bool
    @NSManaged public private(set) var category: String?
    
    // many-to-one relationship
    @NSManaged public private(set) var status: Status?
}

public extension Emoji {
    override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(Emoji.identifier))
    }

    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Emoji {
        let emoji: Emoji = context.insertObject()
        emoji.shortcode = property.shortcode
        emoji.url = property.url
        emoji.staticURL = property.staticURL
        emoji.visibleInPicker = property.visibleInPicker
        return emoji
    }
}

public extension Emoji {
    struct Property {
        
        public let shortcode: String
        public let url: String
        public let staticURL: String
        public let visibleInPicker: Bool
        public let category: String?
        
        public init(shortcode: String, url: String, staticURL: String, visibleInPicker: Bool, category: String?) {
            self.shortcode = shortcode
            self.url = url
            self.staticURL = staticURL
            self.visibleInPicker = visibleInPicker
            self.category = category
        }

    }
}

extension Emoji: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Emoji.createAt, ascending: false)]
    }
}
