//
//  Emoji.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/2/1.
//

import CoreData
import Foundation

public final class Emoji: NSManagedObject {
    public typealias ID = String
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var shortcode: String
    @NSManaged public private(set) var url: String
    @NSManaged public private(set) var staticURL: String
    @NSManaged public private(set) var visibleInPicker: Bool
    @NSManaged public private(set) var toot: Toot?
}

public extension Emoji {
    @discardableResult
    static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Emoji {
        let emoji: Emoji = context.insertObject()

        emoji.identifier = UUID().uuidString
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
        
        public init(shortcode: String, url: String, staticURL: String, visibleInPicker: Bool) {
            self.shortcode = shortcode
            self.url = url
            self.staticURL = staticURL
            self.visibleInPicker = visibleInPicker
        }
    }
}

extension Emoji: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Emoji.identifier, ascending: false)]
    }
}
