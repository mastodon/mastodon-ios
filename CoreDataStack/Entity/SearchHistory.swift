//
//  SearchHistory.swift
//  CoreDataStack
//
//  Created by sxiaojian on 2021/4/7.
//

import Foundation
import CoreData

public final class SearchHistory: NSManagedObject {
    public typealias ID = UUID
    @NSManaged public private(set) var identifier: ID
    @NSManaged public private(set) var domain: String
    @NSManaged public private(set) var userID: MastodonUser.ID
    @NSManaged public private(set) var createAt: Date
    @NSManaged public private(set) var updatedAt: Date

    // one-to-one relationship
    @NSManaged public private(set) var account: MastodonUser?
    @NSManaged public private(set) var hashtag: Tag?
    @NSManaged public private(set) var status: Status?

}

extension SearchHistory {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(SearchHistory.identifier))
        setPrimitiveValue(Date(), forKey: #keyPath(SearchHistory.createAt))
        setPrimitiveValue(Date(), forKey: #keyPath(SearchHistory.updatedAt))
    }
    
    public override func willSave() {
        super.willSave()
        setPrimitiveValue(Date(), forKey: #keyPath(SearchHistory.updatedAt))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        account: MastodonUser
    ) -> SearchHistory {
        let searchHistory: SearchHistory = context.insertObject()
        searchHistory.domain = property.domain
        searchHistory.userID = property.userID
        searchHistory.account = account
        return searchHistory
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        hashtag: Tag
    ) -> SearchHistory {
        let searchHistory: SearchHistory = context.insertObject()
        searchHistory.domain = property.domain
        searchHistory.userID = property.userID
        searchHistory.hashtag = hashtag
        return searchHistory
    }

    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        property: Property,
        status: Status
    ) -> SearchHistory {
        let searchHistory: SearchHistory = context.insertObject()
        searchHistory.domain = property.domain
        searchHistory.userID = property.userID
        searchHistory.status = status
        return searchHistory
    }
}

extension SearchHistory {
    public func update(updatedAt: Date) {
        setValue(updatedAt, forKey: #keyPath(SearchHistory.updatedAt))
    }
}

extension SearchHistory {
    public struct Property {
        public let domain: String
        public let userID: MastodonUser.ID

        public init(domain: String, userID: MastodonUser.ID) {
            self.domain = domain
            self.userID = userID
        }
    }
}

extension SearchHistory: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \SearchHistory.updatedAt, ascending: false)]
    }
}
