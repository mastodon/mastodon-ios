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

    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var identifier: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var domain: String
    // sourcery: autoGenerateProperty
    @NSManaged public private(set) var id: String

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
    
    // many-to-many relationship
    @NSManaged public private(set) var favourite: Set<Status>
    @NSManaged public private(set) var reblogged: Set<Status>
    @NSManaged public private(set) var muted: Set<Status>
    @NSManaged public private(set) var bookmarked: Set<Status>
    // relationships
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
    
    public static func predicate(followingBy userID: String) -> NSPredicate {
        NSPredicate(format: "ANY %K.%K == %@", #keyPath(MastodonUser.followingBy), #keyPath(MastodonUser.id), userID)
    }
    
    public static func predicate(followRequestedBy userID: String) -> NSPredicate {
        NSPredicate(format: "ANY %K.%K == %@", #keyPath(MastodonUser.followRequestedBy), #keyPath(MastodonUser.id), userID)
    }
}
