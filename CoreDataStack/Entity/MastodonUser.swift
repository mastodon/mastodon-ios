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
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var pinnedToot: Toot?
    @NSManaged public private(set) var mastodonAuthentication: MastodonAuthentication?
    
    // one-to-many relationship
    @NSManaged public private(set) var toots: Set<Toot>?
    
    // many-to-many relationship
    @NSManaged public private(set) var favourite: Set<Toot>?
    @NSManaged public private(set) var reblogged: Set<Toot>?
    @NSManaged public private(set) var muted: Set<Toot>?
    @NSManaged public private(set) var bookmarked: Set<Toot>?
    @NSManaged public private(set) var votePollOptions: Set<PollOption>?
        
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
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

public extension MastodonUser {
    struct Property {
        public let identifier: String
        public let domain: String
        
        public let id: String
        public let acct: String
        public let username: String
        public let displayName: String
        public let avatar: String
        public let avatarStatic: String?
        
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
