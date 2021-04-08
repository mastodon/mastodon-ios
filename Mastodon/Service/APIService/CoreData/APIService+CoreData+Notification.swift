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
        property: Setting.Property
    ) -> (Subscription: Setting, isCreated: Bool) {
        let oldSetting: Setting? = {
            let request = Setting.sortedFetchRequest
            request.predicate = Setting.predicate(domain: property.domain)
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
        triggerBy: String? = nil
    ) -> (Subscription: Subscription, isCreated: Bool) {
        // create setting entity if possible
        let oldSetting: Setting? = {
            let request = Setting.sortedFetchRequest
            request.predicate = Setting.predicate(domain: domain)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try managedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        var setting: Setting!
        if let oldSetting = oldSetting {
            setting = oldSetting
        } else {
            let property = Setting.Property(
                appearance: "automatic",
                triggerBy: "anyone",
                domain: domain)
            (setting, _) = createOrMergeSetting(
                into: managedObjectContext,
                domain: domain,
                property: property)
        }
        
        let oldSubscription: Subscription? = {
            let request = Subscription.sortedFetchRequest
            request.predicate = Subscription.predicate(id: entity.id)
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
            type: triggerBy ?? setting.triggerBy ?? "")
        let alertEntity = entity.alerts
        let alert = SubscriptionAlerts.Property(
            favourite: alertEntity.favourite,
            follow: alertEntity.follow,
            mention: alertEntity.mention,
            poll: alertEntity.poll,
            reblog: alertEntity.reblog)
        if let oldSubscription = oldSubscription {
            oldSubscription.updateIfNeed(property: property)
            if nil == oldSubscription.alert {
                oldSubscription.alert = SubscriptionAlerts.insert(
                    into: managedObjectContext,
                    property: alert)
            } else {
                oldSubscription.alert?.updateIfNeed(property: alert)
            }
            
            if oldSubscription.alert?.hasChanges == true {
                // don't expand subscription if add existed subscription
                setting.mutableSetValue(forKey: #keyPath(Setting.subscription)).add(oldSubscription)
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
