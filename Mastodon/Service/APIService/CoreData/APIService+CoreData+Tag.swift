//
//  APIService+CoreData+Tag.swift
//  Mastodon
//
//  Created by sxiaojian on 2021/4/8.
//

import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension APIService.CoreData {
    static func createOrMergeTag(
        into managedObjectContext: NSManagedObjectContext,
        entity: Mastodon.Entity.Tag
    ) -> (Tag: Tag, isCreated: Bool) {
        // fetch old mastodon user
        let oldTag: Tag? = {
            let request = Tag.sortedFetchRequest
            request.predicate = Tag.predicate(name: entity.name)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        if let oldTag = oldTag {
            APIService.CoreData.merge(tag: oldTag, entity: entity, into: managedObjectContext)
            return (oldTag, false)
        } else {
            let histories = entity.history?.prefix(2).compactMap { history -> History in
                History.insert(into: managedObjectContext, property: History.Property(day: history.day, uses: history.uses, accounts: history.accounts))
            }
            let tagInCoreData = Tag.insert(into: managedObjectContext, property: Tag.Property(name: entity.name, url: entity.url, histories: histories))
            return (tagInCoreData, true)
        }
    }
    
    static func merge(tag:Tag,entity:Mastodon.Entity.Tag,into managedObjectContext: NSManagedObjectContext) {
        tag.update(url: tag.url)
        guard let tagHistories = tag.histories else { return }
        guard let entityHistories = entity.history?.prefix(2) else { return }
        let entityHistoriesCount = entityHistories.count
        if entityHistoriesCount == 0 {
            return
        }
        for n in 0..<tagHistories.count {
            if n < entityHistories.count {
                let entityHistory = entityHistories[n]
                tag.updateHistory(index: n, day: entityHistory.day, uses: entityHistory.uses, account: entityHistory.accounts)
            }
        }
        if entityHistoriesCount <= tagHistories.count {
            return
        }
        for n in 1...(entityHistoriesCount - tagHistories.count) {
            let entityHistory = entityHistories[entityHistoriesCount - n]
            tag.appendHistory(history: History.insert(into: managedObjectContext, property: History.Property(day: entityHistory.day, uses: entityHistory.uses, accounts: entityHistory.accounts)))
        }
    }
}
