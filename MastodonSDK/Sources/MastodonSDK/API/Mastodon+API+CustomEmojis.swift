//
//  Mastodon+API+CustomEmojis.swift
//  
//
//  Created by MainasuK Cirno on 2021-3-15.
//

import Foundation
import Combine

extension Mastodon.API.CustomEmojis {

    static func customEmojisEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("custom_emojis")
    }

    /// Custom emoji
    ///
    /// Returns custom emojis that are available on the server.
    ///
    /// - Since: 2.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/3/15
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/custom_emojis/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    /// - Returns: `AnyPublisher` contains [`Emoji`] nested in the response
    public static func customEmojis(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization?
    ) -> AnyPublisher<Mastodon.Response.Content<[Mastodon.Entity.Emoji]>, Error> {
        let request = Mastodon.API.get(
            url: customEmojisEndpointURL(domain: domain),
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: [Mastodon.Entity.Emoji].self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}
