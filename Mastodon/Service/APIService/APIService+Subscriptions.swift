//
//  APIService+Settings.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/9.
//

import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension APIService {
 
    func subscription(
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let domain = mastodonAuthenticationBox.domain
        let userID = mastodonAuthenticationBox.userID
        
        let findSettings: Setting? = {
            let request = Setting.sortedFetchRequest
            request.predicate = Setting.predicate(domain: domain, userID: userID)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try self.backgroundManagedObjectContext.fetch(request).first
            } catch {
                assertionFailure(error.localizedDescription)
                return nil
            }
        }()
        let triggerBy = findSettings?.triggerBy ?? "anyone"
        let setting = self.createSettingIfNeed(
            domain: domain,
            userId: userID,
            triggerBy: triggerBy
        )
        return Mastodon.API.Subscriptions.subscription(
            session: session,
            domain: domain,
            authorization: authorization
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> in
            return self.backgroundManagedObjectContext.performChanges {
                _ = APIService.CoreData.createOrMergeSubscription(
                    into: self.backgroundManagedObjectContext,
                    entity: response.value,
                    domain: domain,
                    triggerBy: triggerBy,
                    setting: setting)
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func createSubscription(
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        query: Mastodon.API.Subscriptions.CreateSubscriptionQuery,
        triggerBy: String,
        userID: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let domain = mastodonAuthenticationBox.domain
        let userID = mastodonAuthenticationBox.userID
        
        let setting = self.createSettingIfNeed(
            domain: domain,
            userId: userID,
            triggerBy: triggerBy
        )
        return Mastodon.API.Subscriptions.createSubscription(
            session: session,
            domain: domain,
            authorization: authorization,
            query: query
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> in
            return self.backgroundManagedObjectContext.performChanges {
                _ = APIService.CoreData.createOrMergeSubscription(
                    into: self.backgroundManagedObjectContext,
                    entity: response.value,
                    domain: domain,
                    triggerBy: triggerBy,
                    setting: setting
                )
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func updateSubscription(
        domain: String,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        query: Mastodon.API.Subscriptions.UpdateSubscriptionQuery,
        triggerBy: String,
        userID: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        
        let setting = self.createSettingIfNeed(domain: domain,
                                               userId: userID,
                                               triggerBy: triggerBy)
        
        return Mastodon.API.Subscriptions.updateSubscription(
            session: session,
            domain: domain,
            authorization: authorization,
            query: query
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> in
            return self.backgroundManagedObjectContext.performChanges {
                _ = APIService.CoreData.createOrMergeSubscription(
                    into: self.backgroundManagedObjectContext,
                    entity: response.value,
                    domain: domain,
                    triggerBy: triggerBy,
                    setting: setting
                )
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func createSettingIfNeed(domain: String, userId: String, triggerBy: String) -> Setting {
        // create setting entity if possible
        let oldSetting: Setting? = {
            let request = Setting.sortedFetchRequest
            request.predicate = Setting.predicate(domain: domain, userID: userId)
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            do {
                return try backgroundManagedObjectContext.fetch(request).first
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
                triggerBy: triggerBy,
                domain: domain,
                userID: userId)
            (setting, _) = APIService.CoreData.createOrMergeSetting(
                into: backgroundManagedObjectContext,
                domain: domain,
                userID: userId,
                property: property
            )
        }
        return setting
    }
}

