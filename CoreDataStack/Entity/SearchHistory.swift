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
    @NSManaged public private(set) var createAt: Date
    @NSManaged public private(set) var updatedAt: Date
    
    @NSManaged public private(set) var account: MastodonUser?
    @NSManaged public private(set) var hashtag: Tag?

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
        account: MastodonUser
    ) -> SearchHistory {
        let searchHistory: SearchHistory = context.insertObject()
        searchHistory.account = account
        return searchHistory
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        hashtag: Tag
    ) -> SearchHistory {
        let searchHistory: SearchHistory = context.insertObject()
        searchHistory.hashtag = hashtag
        return searchHistory
    }
}

public extension SearchHistory {
    func update(updatedAt: Date) {
        setValue(updatedAt, forKey: #keyPath(SearchHistory.updatedAt))
    }
}

extension SearchHistory: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \SearchHistory.updatedAt, ascending: false)]
    }
}
