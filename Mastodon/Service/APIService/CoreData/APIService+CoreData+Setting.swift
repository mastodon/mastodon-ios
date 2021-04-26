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
        property: Setting.Property
    ) -> (Subscription: Setting, isCreated: Bool) {
        let oldSetting: Setting? = {
            let request = Setting.sortedFetchRequest
            request.predicate = Setting.predicate(domain: property.domain, userID: property.userID)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            return managedObjectContext.safeFetch(request).first
        }()
        
        if let oldSetting = oldSetting {
            return (oldSetting, false)
        } else {
            let setting = Setting.insert(
                into: managedObjectContext,
                property: property
            )
            let policies: [Mastodon.API.Subscriptions.Policy] = [
                .all,
                .followed,
                .follower,
                .none
            ]
            let now = Date()
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
            
            
            return (setting, true)
        }
    }

}
