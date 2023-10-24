// Copyright © 2023 Mastodon gGmbH. All rights reserved.

import Foundation
import CoreData

public final class StatusEdit: NSManagedObject {
    public final class Poll: NSObject, Codable {
        public final class Option: NSObject, Codable {
            public let title: String
            
            public init(title: String) {
                self.title = title
            }
        }
        public let options: [Option]
        
        public init(options: [Option]) {
            self.options = options
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var createdAt: Date

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var content: String

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var sensitive: Bool

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var spoilerText: String?

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public var status: Status?

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
        public let attachments: [MastodonAttachment]
        public let poll: Poll?

        public init(
            createdAt: Date,
            content: String,
            sensitive: Bool,
            spoilerText: String?,
            emojis: [MastodonEmoji],
            attachments: [MastodonAttachment],
            poll: Poll?
        ) {
            self.createdAt = createdAt
            self.content = content
            self.sensitive = sensitive
            self.spoilerText = spoilerText
            self.emojis = emojis
            self.attachments = attachments
            self.poll = poll
        }
    }

    public func configure(property: Property) {
        self.createdAt = property.createdAt
        self.content = property.content
        self.sensitive = property.sensitive
        self.spoilerText = property.spoilerText
        self.emojis = property.emojis
        self.attachments = property.attachments
        self.poll = property.poll
    }

    public func update(property: Property) {
        update(createdAt: property.createdAt)
        update(content: property.content)
        update(sensitive: property.sensitive)
        update(spoilerText: property.spoilerText)
        update(emojis: property.emojis)
        update(attachments: property.attachments)
        update(poll: property.poll)
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

extension StatusEdit {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var attachments: [MastodonAttachment] {
        get {
            let keyPath = #keyPath(StatusEdit.attachments)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let attachments = try JSONDecoder().decode([MastodonAttachment].self, from: data)
                return attachments
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(StatusEdit.attachments)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }

}

extension StatusEdit {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var poll: Poll? {
        get {
            let keyPath = #keyPath(StatusEdit.poll)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return nil }
                let poll = try JSONDecoder().decode(Poll.self, from: data)
                return poll
            } catch {
                return nil
            }
        }
        set {
            let keyPath = #keyPath(StatusEdit.poll)
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
    public func update(status: Status?) {
    	if self.status != status {
    		self.status = status
    	}
    }
    public func update(emojis: [MastodonEmoji]) {
    	if self.emojis != emojis {
    		self.emojis = emojis
    	}
    }
    public func update(attachments: [MastodonAttachment]) {
    	if self.attachments != attachments {
    		self.attachments = attachments
    	}
    }
    public func update(poll: Poll?) {
    	if self.poll != poll {
    		self.poll = poll
    	}
    }
    // sourcery:end

}

