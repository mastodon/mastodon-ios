//
//  Mastodon+API+App.swift
//
//
//  Created by xiaojian sun on 2021/1/25.
//

import Foundation
import Combine

extension Mastodon.API.App {

    static func appEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("apps")
    }
    
    static func verifyCredentialsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("apps/verify_credentials")
    }
    
    /// Create an application
    ///
    /// Using this endpoint to obtain `client_id` and `client_secret` for later OAuth token exchange
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `CreateQuery`
    /// - Returns: `AnyPublisher` contains `Application` nested in the response
    public static func create(
        session: URLSession,
        domain: String,
        query: CreateQuery
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Application>, Error>  {
        let request = Mastodon.API.post(
            url: appEndpointURL(domain: domain),
            query: query,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Application.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    /// Verify application token
    ///
    /// Using this endpoint to verify App token
    ///
    /// - Since: 2.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - authorization: App token
    /// - Returns: `AnyPublisher` contains `Application` nested in the response
    public static func verifyCredentials(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Application>, Error> {
        let request = Mastodon.API.get(
            url: verifyCredentialsEndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Application.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

}

extension Mastodon.API.App {
    
    public struct CreateQuery: Codable, PostQuery {
        public let clientName: String
        public let redirectURIs: String
        public let scopes: String?
        public let website: String?
        
        enum CodingKeys: String, CodingKey {
            case clientName = "client_name"
            case redirectURIs = "redirect_uris"
            case scopes
            case website
        }
        
        public init(
            clientName: String,
            redirectURIs: String,
            scopes: String? = "read write follow push",
            website: String?
        ) {
            self.clientName = clientName
            self.redirectURIs = redirectURIs
            self.scopes = scopes
            self.website = website
        }
    }
    
}
