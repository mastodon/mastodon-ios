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
        public let emojis: [MastodonEmoji]

        public init(
            createdAt: Date,
            content: String,
            sensitive: Bool,
            spoilerText: String?,
            emojis: [MastodonEmoji]
        ) {
            self.createdAt = createdAt
            self.content = content
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.emojis = emojis
        }
    }

    public func configure(property: Property) {
        self.createdAt = property.createdAt
        self.content = property.content
        self.sensitive = property.sensitive
        self.spoilerText = property.spoilerText
        self.emojis = property.emojis
    }

    public func update(property: Property) {
        update(createdAt: property.createdAt)
        update(content: property.content)
        update(sensitive: property.sensitive)
        update(spoilerText: property.spoilerText)
        update(emojis: property.emojis)
    }
    // sourcery:end

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var emojis: [MastodonEmoji] {
        get {
            let keyPath = #keyPath(StatusEdit.emojis)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let emojis = try JSONDecoder().decode([MastodonEmoji].self, from: data)
                return emojis
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(StatusEdit.emojis)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
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
    public func update(emojis: [MastodonEmoji]) {
    	if self.emojis != emojis {
    		self.emojis = emojis
    	}
    }
    // sourcery:end

}

