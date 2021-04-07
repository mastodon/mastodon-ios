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
    
    @NSManaged public private(set) var account: MastodonUser?
    @NSManaged public private(set) var hashtag: Tag?

}

extension SearchHistory {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(SearchHistory.identifier))
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        account: MastodonUser
    ) -> SearchHistory {
        let searchHistory: SearchHistory = context.insertObject()
        searchHistory.account = account
        searchHistory.createAt = Date()
        return searchHistory
    }
    
    @discardableResult
    public static func insert(
        into context: NSManagedObjectContext,
        hashtag: Tag
    ) -> SearchHistory {
        let searchHistory: SearchHistory = context.insertObject()
        searchHistory.hashtag = hashtag
        searchHistory.createAt = Date()
        return searchHistory
    }
}

extension SearchHistory: Managed {
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(keyPath: \SearchHistory.createAt, ascending: false)]
    }
}
