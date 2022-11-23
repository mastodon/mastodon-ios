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
    
    /// Followed Tags
    ///
    /// View your followed hashtags.
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
    public static func tag(
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
}
