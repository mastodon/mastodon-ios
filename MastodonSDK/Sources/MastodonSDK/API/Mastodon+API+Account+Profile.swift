//
//  Mastodon+API+Account+Profile.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 3/6/26.
//

import Foundation
import Combine

extension Mastodon.API.Account {
    
    static func profileEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("profile")
    }
    
    /// Show or hide the featured tab.
    ///
    /// - Since: 4.?
    /// - Version: 4.?
    /// # Last Update
    ///   2026/03/05
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/???/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - showFeaturedTab: `Bool`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` empty response
    public static func setShowFeaturedTab(
        session: URLSession,
        domain: String,
        showFeaturedTab: Bool,
        authorization: Mastodon.API.OAuth.Authorization
    ) /*-> AnyPublisher<Void, Error> */ {
        // TODO: implement
    }
    
    /// Feature an account on your own profile.
    ///
    /// - Since: 4.4
    /// - Version: 4.4
    /// # Last Update
    ///   2026/03/05
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/#endorse)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountToFeature: The account id to feature
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Mastodon.Entity.Relationship` nested in the response
    public static func featureAccount(
        session: URLSession,
        domain: String,
        accountToFeature: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let url = Mastodon.API.Account.accountsEndpointURL(domain: domain).appending(components: accountToFeature, "endorse")
        let request = Mastodon.API.post(
            url: url,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Stop featuring an account on your own profile.
    ///
    /// - Since: 4.4
    /// - Version: 4.4
    /// # Last Update
    ///   2026/03/05
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/#unendorse)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - accountToStopFeaturing: The account id to stop featuring
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Mastodon.Entity.Relationship` nested in the response
    public static func stopFeaturingAccount(
        session: URLSession,
        domain: String,
        accountToStopFeaturing: Mastodon.Entity.Account.ID,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Relationship>, Error>  {
        let url = Mastodon.API.Account.accountsEndpointURL(domain: domain).appending(components: accountToStopFeaturing, "unendorse")
        let request = Mastodon.API.post(
            url: url,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Relationship.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
