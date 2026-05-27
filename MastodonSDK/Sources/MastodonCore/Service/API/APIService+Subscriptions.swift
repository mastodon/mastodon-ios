//
//  APIService+Settings.swift
//  Mastodon
//
//  Created by ihugo on 2021/4/9.
//

import Combine
import Foundation
import MastodonSDK

extension APIService {
 
    public func subscribeToPushNotifications(
        query: Mastodon.API.Subscriptions.CreateSubscriptionQuery,
        mastodonAuthenticationBox: MastodonAuthenticationBox
    ) async throws -> Mastodon.Entity.Subscription {
        let authorization = mastodonAuthenticationBox.userAuthorization
        let domain = mastodonAuthenticationBox.domain
        
        let responseContent = try await Mastodon.API.Subscriptions.createSubscription(
            session: session,
            domain: domain,
            authorization: authorization,
            query: query
        )
        
        let newSubscription = responseContent.value
        return newSubscription
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
        
        return response
    }

}

