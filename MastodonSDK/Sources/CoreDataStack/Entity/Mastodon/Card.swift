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
    @NSManaged public private(set) var url: String
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
    @NSManaged public private(set) var authorURL: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var providerName: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var providerURL: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var width: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var height: Int64
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var image: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var embedURL: String?
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var blurhash: String?

    // one-to-one relationship
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
        public let url: String
        public let title: String
        public let desc: String
        public let type: MastodonCardType
        public let authorName: String?
        public let authorURL: String?
        public let providerName: String?
        public let providerURL: String?
        public let width: Int64
        public let height: Int64
        public let image: String?
        public let embedURL: String?
        public let blurhash: String?

    	public init(
    		url: String,
    		title: String,
    		desc: String,
    		type: MastodonCardType,
    		authorName: String?,
    		authorURL: String?,
    		providerName: String?,
    		providerURL: String?,
    		width: Int64,
    		height: Int64,
    		image: String?,
    		embedURL: String?,
    		blurhash: String?
    	) {
    		self.url = url
    		self.title = title
    		self.desc = desc
    		self.type = type
    		self.authorName = authorName
    		self.authorURL = authorURL
    		self.providerName = providerName
    		self.providerURL = providerURL
    		self.width = width
    		self.height = height
    		self.image = image
    		self.embedURL = embedURL
    		self.blurhash = blurhash
    	}
    }

    public func configure(property: Property) {
    	self.url = property.url
    	self.title = property.title
    	self.desc = property.desc
    	self.type = property.type
    	self.authorName = property.authorName
    	self.authorURL = property.authorURL
    	self.providerName = property.providerName
    	self.providerURL = property.providerURL
    	self.width = property.width
    	self.height = property.height
    	self.image = property.image
    	self.embedURL = property.embedURL
    	self.blurhash = property.blurhash
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

    	public init(
    	) {
    	}
    }

    public func configure(relationship: Relationship) {
    }

    // sourcery:end
}
