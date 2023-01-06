import os.log
import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.CoreData {
    
    public struct PersistContext {
        public let domain: String
        public let entity: Mastodon.Entity.V2.Instance
        public let networkDate: Date
        public let log: Logger
        
        public init(
            domain: String,
            entity: Mastodon.Entity.V2.Instance,
            networkDate: Date,
            log: Logger
        ) {
            self.domain = domain
            self.entity = entity
            self.networkDate = networkDate
            self.log = log
        }
    }
    
    static func createOrMergeInstance(
        in managedObjectContext: NSManagedObjectContext,
        context: PersistContext
    ) -> (instance: Instance, isCreated: Bool) {
        // fetch old mastodon user
        let old: Instance? = {
            let request = Instance.sortedFetchRequest
            request.predicate = Instance.predicate(domain: context.domain)
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
            APIService.CoreData.merge(
                instance: old,
                context: context
            )
            return (old, false)
        } else {
            let instance = Instance.insert(
                into: managedObjectContext,
                property: Instance.Property(domain: context.domain, version: context.entity.version)
            )
            let configurationRaw = context.entity.configuration.flatMap { Instance.encodeV2(configuration: $0) }
            instance.update(configurationV2Raw: configurationRaw)
            
            return (instance, true)
        }
    }
    
}

extension APIService.CoreData {
    
    static func merge(
        instance: Instance,
        context: PersistContext
    ) {
        guard context.networkDate > instance.updatedAt else { return }

        let configurationRaw = context.entity.configuration.flatMap { Instance.encodeV2(configuration: $0) }
        instance.update(configurationV2Raw: configurationRaw)
        instance.version = context.entity.version

        instance.didUpdate(at: context.networkDate)
    }
    
}
