//
//  Mastodin+API+Tags.swift
//  
//
//  Created by Marcus Kida on 23.11.22.
//

import Combine
import Foundation

extension Mastodon.API.Tags {
    static func tagsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain)
            .appendingPathComponent("tags")
    }
    
    /// Tags
    ///
    /// View information about a single tag.
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.3
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/tags/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    ///   - tagId: The Hashtag
    /// - Returns: `AnyPublisher` contains `Tag` nested in the response
    public static func getTagInformation(
        session: URLSession,
        domain: String,
        tagId: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Tag>, Error> {
        let request = Mastodon.API.get(
            url: tagsEndpointURL(domain: domain).appendingPathComponent(tagId),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Tag.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Tags
    ///
    /// Follow a hashtag.
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.3
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/tags/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    ///   - tagId: The Hashtag
    /// - Returns: `AnyPublisher` contains `Tag` nested in the response
    public static func followTag(
        session: URLSession,
        domain: String,
        tagId: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Tag>, Error> {
        let request = Mastodon.API.post(
            url: tagsEndpointURL(domain: domain).appendingPathComponent(tagId)
                .appendingPathComponent("follow"),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Tag.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Tags
    ///
    /// Unfollow a hashtag.
    ///
    /// - Since: 4.0.0
    /// - Version: 4.0.3
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/tags/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: User token
    ///   - tagId: The Hashtag
    /// - Returns: `AnyPublisher` contains `Tag` nested in the response
    public static func unfollowTag(
        session: URLSession,
        domain: String,
        tagId: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Tag>, Error> {
        let request = Mastodon.API.post(
            url: tagsEndpointURL(domain: domain).appendingPathComponent(tagId)
                .appendingPathComponent("unfollow"),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Tag.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
