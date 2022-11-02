//
//  MastodonAuthentication.swift
//  CoreDataStack
//
//  Created by MainasuK Cirno on 2021/2/3.
//

import Foundation
import CoreData

final public class MastodonAuthentication: NSManagedObject {
    
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
    
    // many-to-one relationship
    @NSManaged public private(set) var instance: Instance?
    
}

extension MastodonAuthentication {
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        setPrimitiveValue(UUID(), forKey: #keyPath(MastodonAuthentication.identifier))
        let now = Date()
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthentication.createdAt))
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthentication.updatedAt))
        setPrimitiveValue(now, forKey: #keyPath(MastodonAuthentication.activedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        user: MastodonUser
    ) -> MastodonAuthentication {
        let authentication: MastodonAuthentication = context.insertObject()
        
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
    
    public func update(instance: Instance) {
        if self.instance != instance {
            self.instance = instance
        }
    }
    
    public func didUpdate(at networkDate: Date) {
        self.updatedAt = networkDate
    }
    
}

extension MastodonAuthentication {
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

extension MastodonAuthentication: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonAuthentication.createdAt, ascending: false)]
    }
    
    public static var activeSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \MastodonAuthentication.activedAt, ascending: false)]
    }
}

extension MastodonAuthentication {
    public static var activeSortedFetchRequest: NSFetchRequest<MastodonAuthentication> {
        let request = NSFetchRequest<MastodonAuthentication>(entityName: entityName)
        request.sortDescriptors = activeSortDescriptors
        return request
    }
}

extension MastodonAuthentication {
    
    public static func predicate(domain: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthentication.domain), domain)
    }
    
    static func predicate(userID: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthentication.userID), userID)
    }
    
    public static func predicate(domain: String, userID: String) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            MastodonAuthentication.predicate(domain: domain),
            MastodonAuthentication.predicate(userID: userID)
        ])
    }
    
    public static func predicate(userAccessToken: String) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthentication.userAccessToken), userAccessToken)
    }
    
    public static func predicate(identifier: UUID) -> NSPredicate {
        return NSPredicate(format: "%K == %@", #keyPath(MastodonAuthentication.identifier), identifier as NSUUID)
    }
    
    public static func predicate(identifiers: [UUID]) -> NSPredicate {
        return NSPredicate(format: "%K IN %@", #keyPath(MastodonAuthentication.identifier), identifiers as [NSUUID])
    }
    
}
