//
//  APIService+CoreData+Setting.swift
//  Mastodon
//
//  Created by MainasuK Cirno on 2021-4-25.
//


import os.log
import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.CoreData {
    
    static func createOrMergeSetting(
        into managedObjectContext: NSManagedObjectContext,
        property: LegacySetting.Property
    ) -> (Subscription: LegacySetting, isCreated: Bool) {
        let oldSetting: LegacySetting? = {
            let request = LegacySetting.sortedFetchRequest
            request.predicate = LegacySetting.predicate(domain: property.domain, userID: property.userID)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            return managedObjectContext.safeFetch(request).first
        }()
        
        if let oldSetting = oldSetting {
            setupSettingSubscriptions(managedObjectContext: managedObjectContext, setting: oldSetting)
            return (oldSetting, false)
        } else {
            let setting = LegacySetting.insert(
                into: managedObjectContext,
                property: property
            )
            setupSettingSubscriptions(managedObjectContext: managedObjectContext, setting: setting)
            return (setting, true)
        }
    }

}

extension APIService.CoreData {

    static func setupSettingSubscriptions(
        managedObjectContext: NSManagedObjectContext,
        setting: LegacySetting
    ) {
        guard (setting.subscriptions ?? Set()).isEmpty else { return }
        
        let now = Date()
        let policies: [Mastodon.API.Subscriptions.Policy] = [
            .all,
            .followed,
            .follower,
            .none
        ]
        policies.forEach { policy in
            let (subscription, _) = createOrFetchSubscription(
                into: managedObjectContext,
                setting: setting,
                policy: policy
            )
            if policy == .all {
                subscription.update(activedAt: now)
            } else {
                subscription.update(activedAt: now.addingTimeInterval(-10))
            }
        }
        
        // trigger setting update
        setting.didUpdate(at: now)
    }
    
}
