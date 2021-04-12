//
//  APIService+Settings.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/9.
//

import Foundation
import MastodonSDK
import Combine

extension APIService {
 
    func subscription(
        domain: String,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        
        
        return Mastodon.API.Notification.subscription(
            session: session,
            domain: domain,
            authorization: authorization)
            .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> in
                return self.backgroundManagedObjectContext.performChanges {
                    _ = APIService.CoreData.createOrMergeSubscription(
                        into: self.backgroundManagedObjectContext,
                        entity: response.value,
                        domain: domain)
                }
                .setFailureType(to: Error.self)
                .map { _ in return response }
                .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }
    
    func changeSubscription(
        domain: String,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        query: Mastodon.API.Notification.CreateSubscriptionQuery,
        triggerBy: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        
        return Mastodon.API.Notification.createSubscription(
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
                    triggerBy: triggerBy)
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    func updateSubscription(
        domain: String,
        mastodonAuthenticationBox: AuthenticationService.MastodonAuthenticationBox,
        query: Mastodon.API.Notification.UpdateSubscriptionQuery,
        triggerBy: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        
        return Mastodon.API.Notification.updateSubscription(
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
                    triggerBy: triggerBy)
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

