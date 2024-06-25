//
//  MastodonAuthentication.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import CoreData

@objc(MastodonAuthentication)
final public class MastodonAuthenticationLegacy: NSManagedObject {
    
    public typealias ID = UUID
    
    @NSManaged public private(set) var identifier: ID
    
    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var userID: String
    @NSManaged public private(set) var username: String

    @NSManaged public private(set) var appAccessToken: String
    @NSManaged public private(set) var userAccessToken: String
    @NSManaged public private(set) var clientID: String
    @NSManaged public private(set) var clientSecret: String
    
    @NSManaged public private(set) var createdAt: Date
    @NSManaged public private(set) var updatedAt: Date
    @NSManaged public private(set) var activedAt: Date
    
    // one-to-one relationship
    @NSManaged public private(set) var user: MastodonUser    
}

extension MastodonAuthenticationLegacy {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID(), forKey: #keyPath(MastodonAuthenticationLegacy.identifier))
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthenticationLegacy.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthenticationLegacy.updatedAt))
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthenticationLegacy.activedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        user: MastodonUser
    ) -> MastodonAuthenticationLegacy {
        let authentication: MastodonAuthenticationLegacy = context.insertObject()
        
        authentication.domain = property.domain
        authentication.userID = property.userID
        authentication.username = property.username
        authentication.appAccessToken = property.appAccessToken
        authentication.userAccessToken = property.userAccessToken
        authentication.clientID = property.clientID
        authentication.clientSecret = property.clientSecret
        
        authentication.user = user
        
        return authentication
    }
    
    public func update(username: String) {
        if self.username != username {
            self.username = username
        }
    }
    public func update(appAccessToken: String) {
        if self.appAccessToken != appAccessToken {
            self.appAccessToken = appAccessToken
        }
    }
    public func update(userAccessToken: String) {
        if self.userAccessToken != userAccessToken {
            self.userAccessToken = userAccessToken
        }
    }
    public func update(clientID: String) {
        if self.clientID != clientID {
            self.clientID = clientID
        }
    }
    public func update(clientSecret: String) {
        if self.clientSecret != clientSecret {
            self.clientSecret = clientSecret
        }
    }
    
    public func update(activedAt: Date) {
        if self.activedAt != activedAt {
            self.activedAt = activedAt
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension MastodonAuthenticationLegacy {
    public struct Property {
        
        public let domain: String
        public let userID: String
        public let username: String
        public let appAccessToken: String
        public let userAccessToken: String
        public let clientID: String
        public let clientSecret: String
    
        public init(
            domain: String,
            userID: String,
            username: String,
            appAccessToken: String,
            userAccessToken: String,
            clientID: String,
            clientSecret: String
        ) {
            self.domain = domain
            self.userID = userID
            self.username = username
            self.appAccessToken = appAccessToken
            self.userAccessToken = userAccessToken
            self.clientID = clientID
            self.clientSecret = clientSecret
        }
        
    }
}

extension MastodonAuthenticationLegacy: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonAuthenticationLegacy.createdAt, ascending: false)]
    }
    
    public static var activeSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonAuthenticationLegacy.activedAt, ascending: false)]
    }
}

extension MastodonAuthenticationLegacy {
    public static var activeSortedFetchRequest: NSFetchRequest<MastodonAuthenticationLegacy> {
        let request = NSFetchRequest<MastodonAuthenticationLegacy>(entityName: entityName)
        request.sortDescriptors = activeSortDescriptors
        return request
    }
}

extension MastodonAuthenticationLegacy {
    
    public static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthenticationLegacy.domain), domain)
    }
    
    static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthenticationLegacy.userID), userID)
    }
    
    public static func predicate(domain: String, userID: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonAuthenticationLegacy.predicate(domain: domain),
            MastodonAuthenticationLegacy.predicate(userID: userID)
        ])
    }
    
    public static func predicate(userAccessToken: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthenticationLegacy.userAccessToken), userAccessToken)
    }
    
    public static func predicate(identifier: UUID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthenticationLegacy.identifier), identifier as NSUUID)
    }
    
    public static func predicate(identifiers: [UUID]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonAuthenticationLegacy.identifier), identifiers as [NSUUID])
    }
    
}
