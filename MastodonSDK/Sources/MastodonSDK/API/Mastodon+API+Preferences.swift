//
//  Mastodon+API+Preferences.swift
//  
//
//  Created by Jed Fox on 2022-11-28.
//


import Foundation
import Combine

extension Mastodon.API.Preferences {

    static func preferencesEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("preferences")
    }

    /// Preferred common behaviors to be shared across clients
    ///
    /// - Since: 2.8.0
    /// - Version: 4.0.2
    /// # Last Update
    ///   2022/11/28
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/preferences/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: App token
    /// - Returns: `AnyPublisher` contains `Preferences` nested in the response
    public static func preferences(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Preferences>, Error>  {
        let request = Mastodon.API.get(
            url: preferencesEndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value: Mastodon.Entity.Preferences

                value = try Mastodon.API.decode(type: Mastodon.Entity.Preferences.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

}
