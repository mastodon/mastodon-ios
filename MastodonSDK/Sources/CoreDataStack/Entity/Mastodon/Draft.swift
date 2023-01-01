//
//  Draft.swift
//  CoreDataStack
//
//  Created by Jed Fox on 2023-01-01.
//

import Foundation
import CoreData
import MastodonCommon

public final class Draft: NSManagedObject {
    @NSManaged public private(set) var identifier: UUID
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var author: MastodonUser

    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var content: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var contentWarning: String?

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
    
    // sourcery: autoGenerateRelationship
    @NSManaged public private(set) var replyTo: Status?
}

extension Draft {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var attachments: [Attachment] {
        get {
            let keyPath = #keyPath(Draft.attachments)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let attachments = try JSONDecoder().decode([Attachment].self, from: data)
                return attachments
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(Draft.attachments)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var poll: Poll? {
        get {
            let keyPath = #keyPath(Draft.poll)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return nil }
                let attachments = try JSONDecoder().decode(Poll.self, from: data)
                return attachments
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }
        set {
            let keyPath = #keyPath(Draft.poll)
            let data = newValue.flatMap { try? JSONEncoder().encode($0) } ?? nil
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
}

extension Draft {
    public final class Attachment: NSObject, Codable {
        public let fileURL: URL
        // Mastodon.Entity.Attachment.ID
        public let remoteID: String?
        
        public init(fileURL: URL, remoteID: String?) {
            self.fileURL = fileURL
            self.remoteID = remoteID
        }
    }

    @objc public final class Poll: NSObject, Codable {
        public init(items: [String], expiration: Draft.Poll.Expiration, multiple: Bool) {
            self.items = items
            self.expiration = expiration
            self.multiple = multiple
        }
        
        public let items: [String]
        public let expiration: Expiration
        public let multiple: Bool
        
        public struct Expiration: RawRepresentable, Codable, Hashable, CaseIterable {
            public static let allCases = [thirtyMinutes, oneHour, sixHours, oneDay, threeDays, sevenDays]
            
            public static let thirtyMinutes = Self(rawValue: 60 * 30)
            public static let oneHour = Self(rawValue: 60 * 60 * 1)
            public static let sixHours = Self(rawValue: 60 * 60 * 6)
            public static let oneDay = Self(rawValue: 60 * 60 * 24)
            public static let threeDays = Self(rawValue: 60 * 60 * 24 * 3)
            public static let sevenDays = Self(rawValue: 60 * 60 * 24 * 7)

            public var rawValue: TimeInterval
            public init(rawValue: TimeInterval) {
                self.rawValue = rawValue
            }

            public var title: String {
                (Date.now..<Date.now.advanced(by: rawValue))
                    .formatted(Date.ComponentsFormatStyle(style: .wide))
            }
        }
    }
}

extension Draft {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> Draft {
        let object: Draft = context.insertObject()
        
        object.configure(property: property)
        object.createdAt = .now
        object.updatedAt = .now
        
        return object
    }
    
    public override func willSave() {
        super.willSave()
        if updatedAt.distance(to: .now).magnitude > 1.0 {
            updatedAt = .now
        }
    }
    
}

extension Draft: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return []
    }
}

// MARK: - AutoGenerateProperty
extension Draft: AutoGenerateProperty {
    // sourcery:inline:Draft.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let content: String
        public let contentWarning: String?
        public let visibility: MastodonVisibility
        public let attachments: [Attachment]
        public let poll: Poll?

    	public init(
    		content: String,
    		contentWarning: String?,
    		visibility: MastodonVisibility,
    		attachments: [Attachment],
    		poll: Poll?
    	) {
    		self.content = content
    		self.contentWarning = contentWarning
    		self.visibility = visibility
    		self.attachments = attachments
    		self.poll = poll
    	}
    }

    public func configure(property: Property) {
    	self.content = property.content
    	self.contentWarning = property.contentWarning
    	self.visibility = property.visibility
    	self.attachments = property.attachments
    	self.poll = property.poll
    }

    public func update(property: Property) {
    	update(content: property.content)
    	update(contentWarning: property.contentWarning)
    	update(visibility: property.visibility)
    	update(attachments: property.attachments)
    	update(poll: property.poll)
    }
    
    // sourcery:end
}

// MARK: - AutoGenerateRelationship
extension Draft: AutoGenerateRelationship {
    // sourcery:inline:Draft.AutoGenerateRelationship

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Relationship {
    	public let author: MastodonUser
    	public let replyTo: Status?

    	public init(
    		author: MastodonUser,
    		replyTo: Status?
    	) {
    		self.author = author
    		self.replyTo = replyTo
    	}
    }

    public func configure(relationship: Relationship) {
    	self.author = relationship.author
    	self.replyTo = relationship.replyTo
    }
    
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension Draft: AutoUpdatableObject {
    // sourcery:inline:Draft.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(content: String) {
    	if self.content != content {
    		self.content = content
    	}
    }
    public func update(contentWarning: String?) {
    	if self.contentWarning != contentWarning {
    		self.contentWarning = contentWarning
    	}
    }
    public func update(visibility: MastodonVisibility) {
    	if self.visibility != visibility {
    		self.visibility = visibility
    	}
    }
    public func update(attachments: [Attachment]) {
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

