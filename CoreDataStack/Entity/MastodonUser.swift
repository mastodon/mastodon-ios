//
//  MastodonUser.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import CoreData
import Foundation

final public class MastodonUser: NSManagedObject {
    
    public typealias ID = String
    
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var domain: String
    
    @NSManaged public private(set) var id: ID
    @NSManaged public private(set) var acct: String
    @NSManaged public private(set) var username: String
    @NSManaged public private(set) var displayName: String
    @NSManaged public private(set) var avatar: String
    @NSManaged public private(set) var avatarStatic: String?
    @NSManaged public private(set) var header: String
    @NSManaged public private(set) var headerStatic: String?
    @NSManaged public private(set) var note: String?
    @NSManaged public private(set) var url: String?
    
    @NSManaged public private(set) var emojisData: Data?
    @NSManaged public private(set) var fieldsData: Data?
    
    @NSManaged public private(set) var statusesCount: NSNumber
    @NSManaged public private(set) var followingCount: NSNumber
    @NSManaged public private(set) var followersCount: NSNumber
    
    @NSManaged public private(set) var locked: Bool
    @NSManaged public private(set) var bot: Bool
    @NSManaged public private(set) var suspended: Bool
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var pinnedStatus: Status?
    @NSManaged public private(set) var mastodonAuthentication: MastodonAuthentication?
    
    // one-to-many relationship
    @NSManaged public private(set) var statuses: Set<Status>?
    @NSManaged public private(set) var notifications: Set<MastodonNotification>?
    @NSManaged public private(set) var searchHistories: Set<SearchHistory>
    
    // many-to-many relationship
    @NSManaged public private(set) var favourite: Set<Status>?
    @NSManaged public private(set) var reblogged: Set<Status>?
    @NSManaged public private(set) var muted: Set<Status>?
    @NSManaged public private(set) var bookmarked: Set<Status>?
    @NSManaged public private(set) var votePollOptions: Set<PollOption>?
    @NSManaged public private(set) var votePolls: Set<Poll>?
    // relationships
    @NSManaged public private(set) var following: Set<MastodonUser>?
    @NSManaged public private(set) var followingBy: Set<MastodonUser>?
    @NSManaged public private(set) var followRequested: Set<MastodonUser>?
    @NSManaged public private(set) var followRequestedBy: Set<MastodonUser>?
    @NSManaged public private(set) var muting: Set<MastodonUser>?
    @NSManaged public private(set) var mutingBy: Set<MastodonUser>?
    @NSManaged public private(set) var blocking: Set<MastodonUser>?
    @NSManaged public private(set) var blockingBy: Set<MastodonUser>?
    @NSManaged public private(set) var endorsed: Set<MastodonUser>?
    @NSManaged public private(set) var endorsedBy: Set<MastodonUser>?
    @NSManaged public private(set) var domainBlocking: Set<MastodonUser>?
    @NSManaged public private(set) var domainBlockingBy: Set<MastodonUser>?
        
}

extension MastodonUser {
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property
    ) -> MastodonUser {
        let user: MastodonUser = context.insertObject()
    
        user.identifier = property.identifier
        user.domain = property.domain
        
        user.id = property.id
        user.acct = property.acct
        user.username = property.username
        user.displayName = property.displayName
        user.avatar = property.avatar
        user.avatarStatic = property.avatarStatic
        user.header = property.header
        user.headerStatic = property.headerStatic
        user.note = property.note
        user.url = property.url
        user.emojisData = property.emojisData
        user.fieldsData = property.fieldsData
        
        user.statusesCount = NSNumber(value: property.statusesCount)
        user.followingCount = NSNumber(value: property.followingCount)
        user.followersCount = NSNumber(value: property.followersCount)
        
        user.locked = property.locked
        user.bot = property.bot ?? false
        user.suspended = property.suspended ?? false
        
        // Mastodon do not provide relationship on the `Account`
        // Update relationship via attribute updating interface
        
        user.createdAt = property.createdAt
        user.updatedAt = property.networkDate

        return user
    }
    
    
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
    public func update(emojisData: Data?) {
        if self.emojisData != emojisData {
            self.emojisData = emojisData
        }
    }
    public func update(fieldsData: Data?) {
        if self.fieldsData != fieldsData {
            self.fieldsData = fieldsData
        }
    }
    public func update(statusesCount: Int) {
        if self.statusesCount.intValue != statusesCount {
            self.statusesCount = NSNumber(value: statusesCount)
        }
    }
    public func update(followingCount: Int) {
        if self.followingCount.intValue != followingCount {
            self.followingCount = NSNumber(value: followingCount)
        }
    }
    public func update(followersCount: Int) {
        if self.followersCount.intValue != followersCount {
            self.followersCount = NSNumber(value: followersCount)
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
    
    public func update(isFollowing: Bool, by mastodonUser: MastodonUser) {
        if isFollowing {
            if !(self.followingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followingBy)).add(mastodonUser)
            }
        } else {
            if (self.followingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followingBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isFollowRequested: Bool, by mastodonUser: MastodonUser) {
        if isFollowRequested {
            if !(self.followRequestedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followRequestedBy)).add(mastodonUser)
            }
        } else {
            if (self.followRequestedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.followRequestedBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isMuting: Bool, by mastodonUser: MastodonUser) {
        if isMuting {
            if !(self.mutingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.mutingBy)).add(mastodonUser)
            }
        } else {
            if (self.mutingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.mutingBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isBlocking: Bool, by mastodonUser: MastodonUser) {
        if isBlocking {
            if !(self.blockingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.blockingBy)).add(mastodonUser)
            }
        } else {
            if (self.blockingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.blockingBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isEndorsed: Bool, by mastodonUser: MastodonUser) {
        if isEndorsed {
            if !(self.endorsedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.endorsedBy)).add(mastodonUser)
            }
        } else {
            if (self.endorsedBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.endorsedBy)).remove(mastodonUser)
            }
        }
    }
    public func update(isDomainBlocking: Bool, by mastodonUser: MastodonUser) {
        if isDomainBlocking {
            if !(self.domainBlockingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.domainBlockingBy)).add(mastodonUser)
            }
        } else {
            if (self.domainBlockingBy ?? Set()).contains(mastodonUser) {
                self.mutableSetValue(forKey: #keyPath(MastodonUser.domainBlockingBy)).remove(mastodonUser)
            }
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension MastodonUser {
    public func findSearchHistory(domain: String, userID: MastodonUser.ID) -> SearchHistory? {
        return searchHistories.first { searchHistory in
            return searchHistory.domain == domain
                && searchHistory.userID == userID
        }
    }
}

extension MastodonUser {
    public struct Property {
        public let identifier: String
        public let domain: String
        
        public let id: String
        public let acct: String
        public let username: String
        public let displayName: String
        public let avatar: String
        public let avatarStatic: String?
        public let header: String
        public let headerStatic: String?
        public let note: String?
        public let url: String?
        public let emojisData: Data?
        public let fieldsData: Data?
        public let statusesCount: Int
        public let followingCount: Int
        public let followersCount: Int
        public let locked: Bool
        public let bot: Bool?
        public let suspended: Bool?
        
        public let createdAt: Date
        public let networkDate: Date
        
        public init(
            id: String,
            domain: String,
            acct: String,
            username: String,
            displayName: String,
            avatar: String,
            avatarStatic: String?,
            header: String,
            headerStatic: String?,
            note: String?,
            url: String?,
            emojisData: Data?,
            fieldsData: Data?,
            statusesCount: Int,
            followingCount: Int,
            followersCount: Int,
            locked: Bool,
            bot: Bool?,
            suspended: Bool?,
            createdAt: Date,
            networkDate: Date
        ) {
            self.identifier = id + "@" + domain
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
            self.emojisData = emojisData
            self.fieldsData = fieldsData
            self.statusesCount = statusesCount
            self.followingCount = followingCount
            self.followersCount = followersCount
            self.locked = locked
            self.bot = bot
            self.suspended = suspended
            self.createdAt = createdAt
            self.networkDate = networkDate
        }
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
    
}
