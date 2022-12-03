//
//  Card.swift
//  CoreDataStack
//
//  Created by Kyle Bashour on 11/23/22.
//

import Foundation
import CoreData

public final class Card: NSManagedObject {
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var urlRaw: String
    public var url: URL? {
        URL(string: urlRaw)
    }

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var title: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var desc: String

    @NSManaged public private(set) var typeRaw: String
    // sourcery: autoGenerateProperty
    public var type: MastodonCardType {
        get { MastodonCardType(rawValue: typeRaw) }
        set { typeRaw = newValue.rawValue }
    }

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var authorName: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var authorURLRaw: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var providerName: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var providerURLRaw: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var width: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var height: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var image: String?
    public var imageURL: URL? {
        image.flatMap(URL.init)
    }

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var embedURLRaw: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var blurhash: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var html: String?

    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var status: Status
}

extension Card {

    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Card {
        let object: Card = context.insertObject()

        object.configure(property: property)

        return object
    }

}

extension Card: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return []
    }
}

// MARK: - AutoGenerateProperty
extension Card: AutoGenerateProperty {
    // sourcery:inline:Card.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let urlRaw: String
        public let title: String
        public let desc: String
        public let type: MastodonCardType
        public let authorName: String?
        public let authorURLRaw: String?
        public let providerName: String?
        public let providerURLRaw: String?
        public let width: Int64
        public let height: Int64
        public let image: String?
        public let embedURLRaw: String?
        public let blurhash: String?
        public let html: String?

    	public init(
    		urlRaw: String,
    		title: String,
    		desc: String,
    		type: MastodonCardType,
    		authorName: String?,
    		authorURLRaw: String?,
    		providerName: String?,
    		providerURLRaw: String?,
    		width: Int64,
    		height: Int64,
    		image: String?,
    		embedURLRaw: String?,
    		blurhash: String?,
    		html: String?
    	) {
    		self.urlRaw = urlRaw
    		self.title = title
    		self.desc = desc
    		self.type = type
    		self.authorName = authorName
    		self.authorURLRaw = authorURLRaw
    		self.providerName = providerName
    		self.providerURLRaw = providerURLRaw
    		self.width = width
    		self.height = height
    		self.image = image
    		self.embedURLRaw = embedURLRaw
    		self.blurhash = blurhash
    		self.html = html
    	}
    }

    public func configure(property: Property) {
    	self.urlRaw = property.urlRaw
    	self.title = property.title
    	self.desc = property.desc
    	self.type = property.type
    	self.authorName = property.authorName
    	self.authorURLRaw = property.authorURLRaw
    	self.providerName = property.providerName
    	self.providerURLRaw = property.providerURLRaw
    	self.width = property.width
    	self.height = property.height
    	self.image = property.image
    	self.embedURLRaw = property.embedURLRaw
    	self.blurhash = property.blurhash
    	self.html = property.html
    }

    public func update(property: Property) {
    }

    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension Card: AutoGenerateRelationship {
    // sourcery:inline:Card.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let status: Status

    	public init(
    		status: Status
    	) {
    		self.status = status
    	}
    }

    public func configure(relationship: Relationship) {
    	self.status = relationship.status
    }

    // sourcery:end
}
