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
    
    /// Update tab display settings
    ///
    /// Change a user's disply settings for the tabs of their profile when viewed by others.
    ///
    /// - Since: API version 8
    /// - Version: API version 8
    /// # Last Update
    ///   2026/03/13
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/profile/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `UpdateTabDisplaySettingsQuery`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Profile` nested in the response
    public static func updateTabDisplaySettings(
        session: URLSession,
        domain: String,
        query: UpdateTabDisplaySettingsQuery,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Profile>, Error>  {
        let url = profileEndpointURL(domain: domain)
        let request = Mastodon.API.putQueryRequest(
            url: url,
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Profile.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct UpdateTabDisplaySettingsQuery: Codable, PutQuery {
        public let showFeaturedTab: Bool
        public let showMediaTab: Bool
        public let showMediaReplies: Bool

        public init(
            showFeaturedTab: Bool,
            showMediaTab: Bool,
            showMediaReplies: Bool
        ) {
            self.showFeaturedTab = showFeaturedTab
            self.showMediaTab = showMediaTab
            self.showMediaReplies = showMediaReplies
        }
        
        var body: Data? {
            do {
                let dict = [
                    "show_featured" : showFeaturedTab,
                    "show_media" : showMediaTab,
                    "show_media_replies" : showMediaReplies
                ]
                return try JSONSerialization.data(withJSONObject: dict)
            } catch {
                assertionFailure("Error creating update tab display settings query body: \(error)")
                return nil
            }
        }
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
