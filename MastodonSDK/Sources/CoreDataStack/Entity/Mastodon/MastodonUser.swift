//
//  MastodonUser.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import CoreData
import Foundation

/// See also `CoreDataStack.MastodonUser`, this extension contains several 
@available(*, deprecated, message: "Replace with Mastodon.Entity.Account")
final public class MastodonUser: NSManagedObject {
    
    public typealias ID = String
    
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var identifier: ID
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: ID

    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var acct: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var username: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var displayName: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var avatar: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var avatarStatic: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var header: String
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var headerStatic: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var note: String?
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var url: String?
    
    @NSManaged public private(set) var emojisData: Data?
    @NSManaged public private(set) var fieldsData: Data?
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var statusesCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var followingCount: Int64
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var followersCount: Int64
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var locked: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var bot: Bool
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var suspended: Bool
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var createdAt: Date
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var pinnedStatus: Status?
    @NSManaged public private(set) var mastodonAuthentication: MastodonAuthenticationLegacy?
    
    // one-to-many relationship
    @NSManaged public private(set) var statuses: Set<Status>
    @NSManaged public private(set) var notifications: Set<Notification>
    
    // many-to-many relationship
    @NSManaged public private(set) var favourite: Set<Status>
    @NSManaged public private(set) var reblogged: Set<Status>
    @NSManaged public private(set) var muted: Set<Status>
    @NSManaged public private(set) var bookmarked: Set<Status>
    @NSManaged public private(set) var votePollOptions: Set<PollOption>
    @NSManaged public private(set) var votePolls: Set<Poll>
    // relationships
    @NSManaged public private(set) var followedTags: Set<Tag>
    @NSManaged public private(set) var following: Set<MastodonUser>
    @NSManaged public private(set) var followingBy: Set<MastodonUser>
    @NSManaged public private(set) var followRequested: Set<MastodonUser>
    @NSManaged public private(set) var followRequestedBy: Set<MastodonUser>
    @NSManaged public private(set) var muting: Set<MastodonUser>
    @NSManaged public private(set) var mutingBy: Set<MastodonUser>
    @NSManaged public private(set) var blocking: Set<MastodonUser>
    @NSManaged public private(set) var blockingBy: Set<MastodonUser>
    @NSManaged public private(set) var endorsed: Set<MastodonUser>
    @NSManaged public private(set) var endorsedBy: Set<MastodonUser>
    @NSManaged public private(set) var domainBlocking: Set<MastodonUser>
    @NSManaged public private(set) var domainBlockingBy: Set<MastodonUser>
    @NSManaged public private(set) var showingReblogs: Set<MastodonUser>
    @NSManaged public private(set) var showingReblogsBy: Set<MastodonUser>
}

extension MastodonUser {
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var emojis: [MastodonEmoji] {
        get {
            let keyPath = #keyPath(MastodonUser.emojis)
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
            let keyPath = #keyPath(MastodonUser.emojis)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
    
    // sourcery: autoUpdatableObject, autoGenerateProperty
    @objc public var fields: [MastodonField] {
        get {
            let keyPath = #keyPath(MastodonUser.fields)
            willAccessValue(forKey: keyPath)
            let _data = primitiveValue(forKey: keyPath) as? Data
            didAccessValue(forKey: keyPath)
            do {
                guard let data = _data else { return [] }
                let fields = try JSONDecoder().decode([MastodonField].self, from: data)
                return fields
            } catch {
                assertionFailure(error.localizedDescription)
                return []
            }
        }
        set {
            let keyPath = #keyPath(MastodonUser.fields)
            let data = try? JSONEncoder().encode(newValue)
            willChangeValue(forKey: keyPath)
            setPrimitiveValue(data, forKey: keyPath)
            didChangeValue(forKey: keyPath)
        }
    }
}

extension MastodonUser {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> MastodonUser {
        let object: MastodonUser = context.insertObject()
        object.configure(property: property)
        return object
    }
    
}

extension MastodonUser: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonUser.createdAt, ascending: false)]
    }
}

extension MastodonUser {
    
    static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonUser.domain), domain)
    }
    
    static func predicate(id: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonUser.id), id)
    }
    
    public static func predicate(domain: String, id: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonUser.predicate(domain: domain),
            MastodonUser.predicate(id: id)
        ])
    }
    
    static func predicate(ids: [String]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonUser.id), ids)
    }
    
    public static func predicate(domain: String, ids: [String]) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonUser.predicate(domain: domain),
            MastodonUser.predicate(ids: ids)
        ])
    }
    
    static func predicate(username: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonUser.username), username)
    }
    
    public static func predicate(domain: String, username: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonUser.predicate(domain: domain),
            MastodonUser.predicate(username: username)
        ])
    }
    
    public static func predicate(followingBy userID: MastodonUser.ID) -> NSPredicate {
        NSPredicate(format: "ANY %K.%K == %@", #keyPath(MastodonUser.followingBy), #keyPath(MastodonUser.id), userID)
    }
    
    public static func predicate(followRequestedBy userID: MastodonUser.ID) -> NSPredicate {
        NSPredicate(format: "ANY %K.%K == %@", #keyPath(MastodonUser.followRequestedBy), #keyPath(MastodonUser.id), userID)
    }
    
}

// MARK: - AutoGenerateProperty
extension MastodonUser: AutoGenerateProperty {
    // sourcery:inline:MastodonUser.AutoGenerateProperty

    // Generated using Sourcery
    // DO NOT EDIT
    public struct Property {
        public let identifier: ID
        public let domain: String
        public let id: ID
        public let acct: String
        public let username: String
        public let displayName: String
        public let avatar: String
        public let avatarStatic: String?
        public let header: String
        public let headerStatic: String?
        public let note: String?
        public let url: String?
        public let statusesCount: Int64
        public let followingCount: Int64
        public let followersCount: Int64
        public let locked: Bool
        public let bot: Bool
        public let suspended: Bool
        public let createdAt: Date
        public let updatedAt: Date
        public let emojis: [MastodonEmoji]
        public let fields: [MastodonField]

    	public init(
    		identifier: ID,
    		domain: String,
    		id: ID,
    		acct: String,
    		username: String,
    		displayName: String,
    		avatar: String,
    		avatarStatic: String?,
    		header: String,
    		headerStatic: String?,
    		note: String?,
    		url: String?,
    		statusesCount: Int64,
    		followingCount: Int64,
    		followersCount: Int64,
    		locked: Bool,
    		bot: Bool,
    		suspended: Bool,
    		createdAt: Date,
    		updatedAt: Date,
    		emojis: [MastodonEmoji],
    		fields: [MastodonField]
    	) {
    		self.identifier = identifier
    		self.domain = domain
    		self.id = id
    		self.acct = acct
    		self.username = username
    		self.displayName = displayName
    		self.avatar = avatar
    		self.avatarStatic = avatarStatic
    		self.header = header
    		self.headerStatic = headerStatic
    		self.note = note
    		self.url = url
    		self.statusesCount = statusesCount
    		self.followingCount = followingCount
    		self.followersCount = followersCount
    		self.locked = locked
    		self.bot = bot
    		self.suspended = suspended
    		self.createdAt = createdAt
    		self.updatedAt = updatedAt
    		self.emojis = emojis
    		self.fields = fields
    	}
    }

    public func configure(property: Property) {
    	self.identifier = property.identifier
    	self.domain = property.domain
    	self.id = property.id
    	self.acct = property.acct
    	self.username = property.username
    	self.displayName = property.displayName
    	self.avatar = property.avatar
    	self.avatarStatic = property.avatarStatic
    	self.header = property.header
    	self.headerStatic = property.headerStatic
    	self.note = property.note
    	self.url = property.url
    	self.statusesCount = property.statusesCount
    	self.followingCount = property.followingCount
    	self.followersCount = property.followersCount
    	self.locked = property.locked
    	self.bot = property.bot
    	self.suspended = property.suspended
    	self.createdAt = property.createdAt
    	self.updatedAt = property.updatedAt
    	self.emojis = property.emojis
    	self.fields = property.fields
    }

    public func update(property: Property) {
    	update(acct: property.acct)
    	update(username: property.username)
    	update(displayName: property.displayName)
    	update(avatar: property.avatar)
    	update(avatarStatic: property.avatarStatic)
    	update(header: property.header)
    	update(headerStatic: property.headerStatic)
    	update(note: property.note)
    	update(url: property.url)
    	update(statusesCount: property.statusesCount)
    	update(followingCount: property.followingCount)
    	update(followersCount: property.followersCount)
    	update(locked: property.locked)
    	update(bot: property.bot)
    	update(suspended: property.suspended)
    	update(createdAt: property.createdAt)
    	update(updatedAt: property.updatedAt)
    	update(emojis: property.emojis)
    	update(fields: property.fields)
    }
    // sourcery:end
}

// MARK: - AutoUpdatableObject
extension MastodonUser: AutoUpdatableObject {
    // sourcery:inline:MastodonUser.AutoUpdatableObject

    // Generated using Sourcery
    // DO NOT EDIT
    public func update(acct: String) {
    	if self.acct != acct {
    		self.acct = acct
    	}
    }
    public func update(username: String) {
    	if self.username != username {
    		self.username = username
    	}
    }
    public func update(displayName: String) {
    	if self.displayName != displayName {
    		self.displayName = displayName
    	}
    }
    public func update(avatar: String) {
    	if self.avatar != avatar {
    		self.avatar = avatar
    	}
    }
    public func update(avatarStatic: String?) {
    	if self.avatarStatic != avatarStatic {
    		self.avatarStatic = avatarStatic
    	}
    }
    public func update(header: String) {
    	if self.header != header {
    		self.header = header
    	}
    }
    public func update(headerStatic: String?) {
    	if self.headerStatic != headerStatic {
    		self.headerStatic = headerStatic
    	}
    }
    public func update(note: String?) {
    	if self.note != note {
    		self.note = note
    	}
    }
    public func update(url: String?) {
    	if self.url != url {
    		self.url = url
    	}
    }
    public func update(statusesCount: Int64) {
    	if self.statusesCount != statusesCount {
    		self.statusesCount = statusesCount
    	}
    }
    public func update(followingCount: Int64) {
    	if self.followingCount != followingCount {
    		self.followingCount = followingCount
    	}
    }
    public func update(followersCount: Int64) {
    	if self.followersCount != followersCount {
    		self.followersCount = followersCount
    	}
    }
    public func update(locked: Bool) {
    	if self.locked != locked {
    		self.locked = locked
    	}
    }
    public func update(bot: Bool) {
    	if self.bot != bot {
    		self.bot = bot
    	}
    }
    public func update(suspended: Bool) {
    	if self.suspended != suspended {
    		self.suspended = suspended
    	}
    }
    public func update(createdAt: Date) {
    	if self.createdAt != createdAt {
    		self.createdAt = createdAt
    	}
    }
    public func update(updatedAt: Date) {
    	if self.updatedAt != updatedAt {
    		self.updatedAt = updatedAt
    	}
    }
    public func update(emojis: [MastodonEmoji]) {
    	if self.emojis != emojis {
    		self.emojis = emojis
    	}
    }
    public func update(fields: [MastodonField]) {
    	if self.fields != fields {
    		self.fields = fields
    	}
    }
    // sourcery:end
    
    public func update(isFollowing: Bool, by mastodonUser: MastodonUser) {
        if isFollowing {
            if !self.followingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followingBy)).add(mastodonUser)
            }
        } else {
            if self.followingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followingBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isFollowRequested: Bool, by mastodonUser: MastodonUser) {
        if isFollowRequested {
            if !self.followRequestedBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followRequestedBy)).add(mastodonUser)
            }
        } else {
            if self.followRequestedBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followRequestedBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isMuting: Bool, by mastodonUser: MastodonUser) {
        if isMuting {
            if !self.mutingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.mutingBy)).add(mastodonUser)
            }
        } else {
            if self.mutingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.mutingBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isBlocking: Bool, by mastodonUser: MastodonUser) {
        if isBlocking {
            if !self.blockingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.blockingBy)).add(mastodonUser)
            }
        } else {
            if self.blockingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.blockingBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isEndorsed: Bool, by mastodonUser: MastodonUser) {
        if isEndorsed {
            if !self.endorsedBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.endorsedBy)).add(mastodonUser)
            }
        } else {
            if self.endorsedBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.endorsedBy)).remove(mastodonUser)
            }
        }
    }

    public func update(isDomainBlocking: Bool, by mastodonUser: MastodonUser) {
        if isDomainBlocking {
            if !self.domainBlockingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.domainBlockingBy)).add(mastodonUser)
            }
        } else {
            if self.domainBlockingBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.domainBlockingBy)).remove(mastodonUser)
            }
        }
    }

    public func update(isShowingReblogs: Bool, by mastodonUser: MastodonUser) {
        if isShowingReblogs {
            if !self.showingReblogsBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.showingReblogsBy)).add(mastodonUser)
            }
        } else {
            if self.showingReblogsBy.contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.showingReblogsBy)).remove(mastodonUser)
            }
        }
    }
}

extension MastodonUser {
    public var verifiedLink: MastodonField? {
        let firstVerified = fields.first(where: { $0.verifiedAt != nil })
        return firstVerified
    }
}
