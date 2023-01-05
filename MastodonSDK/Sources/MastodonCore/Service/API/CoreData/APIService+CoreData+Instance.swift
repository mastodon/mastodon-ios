//
//  APIService+CoreData+Instance.swift
//  Mastodon
//
//  Created by Cirno MainasuK on 2021-10-9.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.CoreData {
    
    static func createOrMergeInstance(
        into managedObjectContext: NSManagedObjectContext,
        domain: String,
        entity: Mastodon.Entity.Instance,
        networkDate: Date,
        log: Logger
    ) -> (instance: Instance, isCreated: Bool) {
        // fetch old mastodon user
        let old: Instance? = {
            let request = Instance.sortedFetchRequest
            request.predicate = Instance.predicate(domain: domain)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        if let old = old {
            // merge old
            APIService.CoreData.merge(
                instance: old,
                entity: entity,
                domain: domain,
                networkDate: networkDate
            )
            return (old, false)
        } else {
            let instance = Instance.insert(
                into: managedObjectContext,
                property: Instance.Property(domain: domain, version: entity.version)
            )
            let configurationRaw = entity.configuration.flatMap { Instance.encode(configuration: $0) }
            instance.update(configurationRaw: configurationRaw)
            
            return (instance, true)
        }
    }
    
}

extension APIService.CoreData {
    
    static func merge(
        instance: Instance,
        entity: Mastodon.Entity.Instance,
        domain: String,
        networkDate: Date
    ) {
        guard networkDate > instance.updatedAt else { return }

        let configurationRaw = entity.configuration.flatMap { Instance.encode(configuration: $0) }
        instance.update(configurationRaw: configurationRaw)
        instance.version = entity.version

        instance.didUpdate(at: networkDate)
    }
    
}
