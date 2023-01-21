// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreData

public final class StatusEdit: NSManagedObject {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var createdAt: Date

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var content: String

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var sensitive: Bool

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var spoilerText: String?

    // MARK: - AutoGenerateProperty
    // sourcery:inline:StatusEdit.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let createdAt: Date
        public let content: String
        public let sensitive: Bool
        public let spoilerText: String?

        public init(
            createdAt: Date,
            content: String,
            sensitive: Bool,
            spoilerText: String?
        ) {
            self.createdAt = createdAt
            self.content = content
            self.sensitive = sensitive
            self.spoilerText = spoilerText
        }
    }

    public func configure(property: Property) {
        self.createdAt = property.createdAt
        self.content = property.content
        self.sensitive = property.sensitive
        self.spoilerText = property.spoilerText
    }

    public func update(property: Property) {
        update(createdAt: property.createdAt)
        update(content: property.content)
        update(sensitive: property.sensitive)
        update(spoilerText: property.spoilerText)
    }
    // sourcery:end
}
extension StatusEdit: Managed {
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> StatusEdit {
        let object: StatusEdit = context.insertObject()

        object.configure(property: property)

        return object
    }
}

extension StatusEdit: AutoUpdatableObject {
    // sourcery:inline:StatusEdit.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(content: String) {
    	if self.content != content {
    		self.content = content
    	}
    }
    public func update(sensitive: Bool) {
    	if self.sensitive != sensitive {
    		self.sensitive = sensitive
    	}
    }
    public func update(spoilerText: String?) {
    	if self.spoilerText != spoilerText {
    		self.spoilerText = spoilerText
    	}
    }
    // sourcery:end

}
