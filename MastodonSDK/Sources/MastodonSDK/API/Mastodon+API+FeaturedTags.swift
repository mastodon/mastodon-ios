//
//  Mastodon+API+FeaturedTags.swift
//  MastodonSDK
//
//  Created by Shannon Hughes on 1/7/26.
//


import Combine
import Foundation

extension Mastodon.API.FeaturedTags {
    
    static func featuredTagsEndpointURL(accountID: String?, domain: String) -> URL {
        guard let accountID else {
            return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("featured_tags")
        }
        
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("accounts")
            .appendingPathComponent(accountID)
            .appendingPathComponent("featured_tags")
    }
    
    /// Featured tags
    ///
    /// Using this endpoint to view the featured tags list for user
    ///
    /// - Since: 3.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2022/7/28
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/accounts/#featured_tags)
    /// - Parameters:
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `[Mastodon.Entity.FeaturedTag]` nested in the response
    public static func featuredTags(
        accountID: Mastodon.Entity.Account.ID?,
        domain: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization,
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.FeaturedTag]>, Error> {
        let url = featuredTagsEndpointURL(accountID: accountID, domain: domain)
        let request = Mastodon.API.get(url: url, query: nil, authorization: authorization)
        RateLimitViewModel.shared.didMakeRequest("get tags featured by \(accountID ?? "(unknown)")")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.FeaturedTag].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}

extension Mastodon.API.FeaturedTags {
    
    /// Feature a Tag
    ///
    /// Add a tag to your featured list
    ///
    /// - Since: 3.0.0
    /// - Version: 3.0.0
    /// # Last Update
    ///   2025/01/09
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/featured_tags/)
    /// - Parameters:
    ///   - tag: Mastodon tag name
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` contains `Mastodon.Entity.FeaturedTag` nested in the response
    public static func feature(
        tag: String,
        domain: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.FeaturedTag>, Error> {
        let url: URL = featuredTagsEndpointURL(accountID: nil, domain: domain)
        var request = Mastodon.API.post(url: url, query: FeaturedTagPostQuery(tagName: tag), authorization: authorization)
        request.httpMethod = "POST"
        RateLimitViewModel.shared.didMakeRequest("start featuring #\(tag)")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.FeaturedTag.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public struct FeaturedTagPostQuery: PostQuery {
        let tagName: String
        
        var contentType: String? {
            "application/json"
        }
        
        var body: Data? {
            do {
                let dict = [ "name" : tagName ]
                return try JSONSerialization.data(withJSONObject: dict)
            } catch {
                assertionFailure("Error creating feature tag post query body: \(error)")
                return nil
            }
        }
    }
    
    /// Unfeature a Tag
    ///
    /// Remove a tag from your featured list
    ///
    /// - Since: 3.0.0
    /// - Version: 3.0.0
    /// # Last Update
    ///   2025/01/07
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/featured_tags/)
    /// - Parameters:
    ///   - tag: Mastodon tag name
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - session: `URLSession`
    ///   - authorization: User token
    /// - Returns: `AnyPublisher` with empty response
    public static func unfeature(
        tag: Mastodon.Entity.FeaturedTag,
        domain: String,
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Void, Error> {
        let url: URL = featuredTagsEndpointURL(accountID: nil, domain: domain).appendingPathComponent(tag.id)
        var request = Mastodon.API.delete(url: url, query: nil, authorization: authorization)
        request.httpMethod = "DELETE"
        RateLimitViewModel.shared.didMakeRequest("stop featuring #\(tag.name)")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                try Mastodon.API.decodeEmpty(from: data, response: response)
                return
            }
            .eraseToAnyPublisher()
    }
    
    public static func getSuggestedTags(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Tag]>, Error> {
        let request = Mastodon.API.get(
            url: featuredTagsEndpointURL(accountID: nil, domain: domain).appendingPathComponent("suggestions"),
            query: nil,
            authorization: authorization
        )
        RateLimitViewModel.shared.didMakeRequest("get suggested tags")
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Array<Mastodon.Entity.Tag>.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
