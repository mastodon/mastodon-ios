//
//  Status.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import CoreData
import Foundation

public final class Status: NSManagedObject {
    public typealias ID = String

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var identifier: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var uri: String
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var editedAt: Date?

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var content: String
    
    @NSManaged public private(set) var visibilityRaw: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    public var visibility: MastodonVisibility {
        get {
            let rawValue = visibilityRaw
            return MastodonVisibility(rawValue: rawValue) ?? ._other(rawValue)
        }
        set {
            visibilityRaw = newValue.rawValue
        }
    }
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var sensitive: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var spoilerText: String?
    
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var isSensitiveToggled: Bool

    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var application: Application?
        
    // Informational
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var reblogsCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var favouritesCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var repliesCount: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var url: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var inReplyToID: Status.ID?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var inReplyToAccountID: String?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var language: String? //  (ISO 639 Part 1 two-letter language code)
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var text: String?
    
    // many-to-one relationship
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var reblog: Status?
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var replyTo: Status?
    
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var card: Card?

    // one-to-many relationship
    @NSManaged public private(set) var feeds: Set<Feed>
    
    @NSManaged public private(set) var reblogFrom: Set<Status>
    @NSManaged public private(set) var replyFrom: Set<Status>
    @NSManaged public private(set) var notifications: Set<Notification>
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var deletedAt: Date?
    // sourcery: autoUpdatableObject
    @NSManaged public private(set) var revealedAt: Date?
}

extension Status {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var attachments: [MastodonAttachment] {
        get {
            let keyPath = #keyPath(Status.attachments)
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
            let keyPath = #keyPath(Status.attachments)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var emojis: [MastodonEmoji] {
        get {
            let keyPath = #keyPath(Status.emojis)
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
            let keyPath = #keyPath(Status.emojis)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var mentions: [MastodonMention] {
        get {
            let keyPath = #keyPath(Status.mentions)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let mentions = try JSONDecoder().decode([MastodonMention].self, from: data)
                return mentions
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(Status.mentions)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
}

extension Status: FeedIndexable { }

extension Status {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        relationship: Relationship
    ) -> Status {
        let object: Status = context.insertObject()
        
        object.configure(property: property)
        object.configure(relationship: relationship)
        
        return object
    }

}

extension Status: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \Status.createdAt, ascending: false)]
    }
}

extension Status {
    
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Status.domain), domain)
    }
    
    static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(Status.id), id)
    }
    
    public static func predicate(domain: String, id: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(id: id)
        ])
    }
    
    static func predicate(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(Status.id), ids)
    }
    
    public static func predicate(domain: String, ids: [String]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            predicate(domain: domain),
            predicate(ids: ids)
        ])
    }
    
    public static func notDeleted() -> NSPredicate {
        return NSPredicate(format: "%K == nil", #keyPath(Status.deletedAt))
    }
    
    public static func deleted() -> NSPredicate {
        return NSPredicate(format: "%K != nil", #keyPath(Status.deletedAt))
    }
    
}

// MARK: - AutoGenerateProperty
extension Status: AutoGenerateProperty {
    // sourcery:inline:Status.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let identifier: ID
        public let domain: String
        public let id: String
        public let uri: String
        public let createdAt: Date
        public let editedAt: Date?
        public let content: String
        public let visibility: MastodonVisibility
        public let sensitive: Bool
        public let spoilerText: String?
        public let reblogsCount: Int64
        public let favouritesCount: Int64
        public let repliesCount: Int64
        public let url: String?
        public let inReplyToID: Status.ID?
        public let inReplyToAccountID: String?
        public let language: String?
        public let text: String?
        public let updatedAt: Date
        public let deletedAt: Date?
        public let attachments: [MastodonAttachment]
        public let emojis: [MastodonEmoji]
        public let mentions: [MastodonMention]

    	public init(
    		identifier: ID,
    		domain: String,
    		id: String,
    		uri: String,
    		createdAt: Date,
    		editedAt: Date?,
    		content: String,
    		visibility: MastodonVisibility,
    		sensitive: Bool,
    		spoilerText: String?,
    		reblogsCount: Int64,
    		favouritesCount: Int64,
    		repliesCount: Int64,
    		url: String?,
    		inReplyToID: Status.ID?,
    		inReplyToAccountID: String?,
    		language: String?,
    		text: String?,
    		updatedAt: Date,
    		deletedAt: Date?,
    		attachments: [MastodonAttachment],
    		emojis: [MastodonEmoji],
    		mentions: [MastodonMention]
    	) {
    		self.identifier = identifier
    		self.domain = domain
    		self.id = id
    		self.uri = uri
    		self.createdAt = createdAt
    		self.editedAt = editedAt
    		self.content = content
    		self.visibility = visibility
    		self.sensitive = sensitive
    		self.spoilerText = spoilerText
    		self.reblogsCount = reblogsCount
    		self.favouritesCount = favouritesCount
    		self.repliesCount = repliesCount
    		self.url = url
    		self.inReplyToID = inReplyToID
    		self.inReplyToAccountID = inReplyToAccountID
    		self.language = language
    		self.text = text
    		self.updatedAt = updatedAt
    		self.deletedAt = deletedAt
    		self.attachments = attachments
    		self.emojis = emojis
    		self.mentions = mentions
    	}
    }

    public func configure(property: Property) {
    	self.identifier = property.identifier
    	self.domain = property.domain
    	self.id = property.id
    	self.uri = property.uri
    	self.createdAt = property.createdAt
    	self.editedAt = property.editedAt
    	self.content = property.content
    	self.visibility = property.visibility
    	self.sensitive = property.sensitive
    	self.spoilerText = property.spoilerText
    	self.reblogsCount = property.reblogsCount
    	self.favouritesCount = property.favouritesCount
    	self.repliesCount = property.repliesCount
    	self.url = property.url
    	self.inReplyToID = property.inReplyToID
    	self.inReplyToAccountID = property.inReplyToAccountID
    	self.language = property.language
    	self.text = property.text
    	self.updatedAt = property.updatedAt
    	self.deletedAt = property.deletedAt
    	self.attachments = property.attachments
    	self.emojis = property.emojis
    	self.mentions = property.mentions
    }

    public func update(property: Property) {
    	update(createdAt: property.createdAt)
    	update(editedAt: property.editedAt)
    	update(content: property.content)
    	update(visibility: property.visibility)
    	update(sensitive: property.sensitive)
    	update(spoilerText: property.spoilerText)
    	update(reblogsCount: property.reblogsCount)
    	update(favouritesCount: property.favouritesCount)
    	update(repliesCount: property.repliesCount)
    	update(url: property.url)
    	update(inReplyToID: property.inReplyToID)
    	update(inReplyToAccountID: property.inReplyToAccountID)
    	update(language: property.language)
    	update(text: property.text)
    	update(updatedAt: property.updatedAt)
    	update(deletedAt: property.deletedAt)
    	update(attachments: property.attachments)
    	update(emojis: property.emojis)
    	update(mentions: property.mentions)
    }
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension Status: AutoGenerateRelationship {
    // sourcery:inline:Status.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let application: Application?
    	public let reblog: Status?
    	public let card: Card?

    	public init(
    		application: Application?,
    		reblog: Status?,
    		card: Card?
    	) {
    		self.application = application
    		self.reblog = reblog
    		self.card = card
    	}
    }

    public func configure(relationship: Relationship) {
    	self.application = relationship.application
    	self.reblog = relationship.reblog
    	self.card = relationship.card
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension Status: AutoUpdatableObject {
    // sourcery:inline:Status.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(editedAt: Date?) {
    	if self.editedAt != editedAt {
    		self.editedAt = editedAt
    	}
    }
    public func update(content: String) {
    	if self.content != content {
    		self.content = content
    	}
    }
    public func update(visibility: MastodonVisibility) {
    	if self.visibility != visibility {
    		self.visibility = visibility
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
    public func update(isSensitiveToggled: Bool) {
    	if self.isSensitiveToggled != isSensitiveToggled {
    		self.isSensitiveToggled = isSensitiveToggled
    	}
    }
    public func update(reblogsCount: Int64) {
    	if self.reblogsCount != reblogsCount {
    		self.reblogsCount = reblogsCount
    	}
    }
    public func update(favouritesCount: Int64) {
    	if self.favouritesCount != favouritesCount {
    		self.favouritesCount = favouritesCount
    	}
    }
    public func update(repliesCount: Int64) {
    	if self.repliesCount != repliesCount {
    		self.repliesCount = repliesCount
    	}
    }
    public func update(url: String?) {
    	if self.url != url {
    		self.url = url
    	}
    }
    public func update(inReplyToID: Status.ID?) {
    	if self.inReplyToID != inReplyToID {
    		self.inReplyToID = inReplyToID
    	}
    }
    public func update(inReplyToAccountID: String?) {
    	if self.inReplyToAccountID != inReplyToAccountID {
    		self.inReplyToAccountID = inReplyToAccountID
    	}
    }
    public func update(language: String?) {
    	if self.language != language {
    		self.language = language
    	}
    }
    public func update(text: String?) {
    	if self.text != text {
    		self.text = text
    	}
    }
    public func update(replyTo: Status?) {
    	if self.replyTo != replyTo {
    		self.replyTo = replyTo
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(deletedAt: Date?) {
    	if self.deletedAt != deletedAt {
    		self.deletedAt = deletedAt
    	}
    }
    public func update(revealedAt: Date?) {
    	if self.revealedAt != revealedAt {
    		self.revealedAt = revealedAt
    	}
    }
    public func update(attachments: [MastodonAttachment]) {
    	if self.attachments != attachments {
    		self.attachments = attachments
    	}
    }
    public func update(emojis: [MastodonEmoji]) {
    	if self.emojis != emojis {
    		self.emojis = emojis
    	}
    }
    public func update(mentions: [MastodonMention]) {
    	if self.mentions != mentions {
    		self.mentions = mentions
    	}
    }
    // sourcery:end
    
    public func update(isReveal: Bool) {
        revealedAt = isReveal ? Date() : nil
    }
}

extension Status {
    public func attach(feed: Feed) {
        mutableSetValue(forKey: #keyPath(Status.feeds)).add(feed)
    }
}
