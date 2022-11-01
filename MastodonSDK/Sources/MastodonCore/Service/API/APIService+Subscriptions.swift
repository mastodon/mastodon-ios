//
//  APIService+Settings.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/9.
//

import os.log
import Combine
import CoreData
import CoreDataStack
import Foundation
import MastodonSDK

extension APIService {
 
    func createSubscription(
        subscriptionObjectID: NSManagedObjectID,
        query: Mastodon.API.Subscriptions.CreateSubscriptionQuery,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let domain = mastodonAuthenticationBox.domain
        
        return Mastodon.API.Subscriptions.createSubscription(
            session: session,
            domain: domain,
            authorization: authorization,
            query: query
        )
        .flatMap { response -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Subscription>, Error> in
            os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: create subscription successful %s", ((#file as NSString).lastPathComponent), #line, #function, response.value.endpoint)

            let managedObjectContext = self.backgroundManagedObjectContext
            return managedObjectContext.performChanges {
                guard let subscription = managedObjectContext.object(with: subscriptionObjectID) as? NotificationSubscription else {
                    assertionFailure()
                    return
                }
                subscription.endpoint = response.value.endpoint
                subscription.serverKey = response.value.serverKey
                subscription.userToken = authorization.accessToken
                subscription.didUpdate(at: response.networkDate)
            }
            .setFailureType(to: Error.self)
            .map { _ in return response }
            .eraseToAnyPublisher()
        }
        .eraseToAnyPublisher()
    }
    
    func cancelSubscription(
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) async throws -> Mastodon.Response.Content<Mastodon.Entity.EmptySubscription> {
        let response = try await Mastodon.API.Subscriptions.removeSubscription(
            session: session,
            domain: domain,
            authorization: authorization
        ).singleOutput()
        
        os_log(.info, log: .debug, "%{public}s[%{public}ld], %{public}s: cancel subscription successful", ((#file as NSString).lastPathComponent), #line, #function)

        return response
    }

}

