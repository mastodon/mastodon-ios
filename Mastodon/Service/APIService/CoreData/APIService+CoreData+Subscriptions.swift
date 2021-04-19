//
//  APIService+CoreData+Notification.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/11.
//

import os.log
import Foundation
import CoreData
import CoreDataStack
import MastodonSDK

extension APIService.CoreData {
    
    static func createOrMergeSetting(
        into managedObjectContext: NSManagedObjectContext,
        domain: String,
        userID: String,
        property: Setting.Property
    ) -> (Subscription: Setting, isCreated: Bool) {
        let oldSetting: Setting? = {
            let request = Setting.sortedFetchRequest
            request.predicate = Setting.predicate(domain: property.domain, userID: userID)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        if let oldSetting = oldSetting {
            return (oldSetting, false)
        } else {
            let setting = Setting.insert(
                into: managedObjectContext,
                property: property)
            return (setting, true)
        }
    }
    
    static func createOrMergeSubscription(
        into managedObjectContext: NSManagedObjectContext,
        entity: Mastodon.Entity.Subscription,
        domain: String,
        triggerBy: String,
        setting: Setting
    ) -> (Subscription: Subscription, isCreated: Bool) {
        let oldSubscription: Subscription? = {
            let request = Subscription.sortedFetchRequest
            request.predicate = Subscription.predicate(type: triggerBy)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        
        let property = Subscription.Property(
            endpoint: entity.endpoint,
            id: entity.id,
            serverKey: entity.serverKey,
            type: triggerBy
        )
        let alertEntity = entity.alerts
        let alert = SubscriptionAlerts.Property(
            favourite: alertEntity.favouriteNumber,
            follow: alertEntity.followNumber,
            mention: alertEntity.mentionNumber,
            poll: alertEntity.pollNumber,
            reblog: alertEntity.reblogNumber
        )
        if let oldSubscription = oldSubscription {
            oldSubscription.updateIfNeed(property: property)
            if nil == oldSubscription.alert {
                oldSubscription.alert = SubscriptionAlerts.insert(
                    into: managedObjectContext,
                    property: alert
                )
            } else {
                oldSubscription.alert?.updateIfNeed(property: alert)
            }
            
            if oldSubscription.alert?.hasChanges == true || oldSubscription.hasChanges {
                // don't expand subscription if add existed subscription
                //setting.mutableSetValue(forKey: #keyPath(Setting.subscription)).add(oldSubscription)
                oldSubscription.didUpdate(at: Date())
            }
            return (oldSubscription, false)
        } else {
            let subscription = Subscription.insert(
                into: managedObjectContext,
                property: property
            )
            subscription.alert = SubscriptionAlerts.insert(
                into: managedObjectContext,
                property: alert)
            setting.mutableSetValue(forKey: #keyPath(Setting.subscription)).add(subscription)
            return (subscription, true)
        }
    }
}
