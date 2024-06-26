//
//  Mastodon+API+Instance.swift
//  
//
//  Created by MainasuK Cirno on 2021-2-5.
//

import Foundation
import Combine

public typealias TranslationLanguages = [String: [String]]

extension Mastodon.API.Instance {

    static func instanceEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("instance")
    }
    
    /// Information about the server
    ///
    /// - Since: 1.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/5
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/instance/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    /// - Returns: `AnyPublisher` contains `Instance` nested in the response
    public static func instance(
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization?,
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Instance>, Error>  {
        let request = Mastodon.API.get(url: instanceEndpointURL(domain: domain), authorization: authorization)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value: Mastodon.Entity.Instance

                do {
                    value = try Mastodon.API.decode(type: Mastodon.Entity.Instance.self, from: data, response: response)
                } catch {
                    if let response = response as? HTTPURLResponse, 400 ..< 500 ~= response.statusCode {
                        // For example, AUTHORIZED_FETCH may result in authentication errors
                        value = Mastodon.Entity.Instance(domain: domain)
                    } else {
                        throw error
                    }
                }
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    static func extendedDescriptionEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("instance").appendingPathComponent("extended_description")
    }

    /// Extended description of the server
    ///
    /// - Returns: A ``MastodonSDK.Mastodon.Entity.ExtendedDescription``
    ///
    /// ## Reference:
    /// [Document](https://docs.joinmastodon.org/methods/instance/#extended_description)
    public static func extendedDescription(
        session: URLSession,
        authorization: Mastodon.API.OAuth.Authorization?,
        domain: String
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.ExtendedDescription>, Error>  {
        let request = Mastodon.API.get(url: extendedDescriptionEndpointURL(domain: domain), authorization: authorization)
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.ExtendedDescription.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
}
