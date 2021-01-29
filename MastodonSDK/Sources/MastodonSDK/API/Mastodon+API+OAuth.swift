//
//  Mastodon+API+OAuth.swift
//  
//
//  Created by MainasuK Cirno on 2021/1/27.
//

import Foundation
import Combine

extension Mastodon.API.OAuth {

    public static let authorizationField = "Authorization"

    public struct Authorization {
        public let accessToken: String
    }

}

extension Mastodon.API.OAuth {
    
    static func authorizeEndpointURL(domain: String) -> URL {
        return Mastodon.API.oauthEndpointURL(domain: domain).appendingPathComponent("authorize")
    }
    
    /// Construct user authorize endpoint URL
    ///
    /// This method construct a URL for user authorize
    ///
    /// - Since: 0.1.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/oauth/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AuthorizeQuery`
    static func authorizeURL(
        domain: String,
        query: AuthorizeQuery
    ) -> URL {
        let request = Mastodon.API.get(
            url: authorizeEndpointURL(domain: domain),
            query: query,
            authorization: nil
        )
        let url = request.url!
        return url
    }
    
//    static func authorize(
//        session: URLSession,
//        domain: String,
//        query: AuthorizeQuery
//    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> {
//        let request = Mastodon.API.post(
//            url: authorizeEndpointURL(domain: domain),
//            query: query,
//            authorization: nil
//        )
//        return session.dataTaskPublisher(for: request)
//            .tryMap { data, response in
//                let value = try Mastodon.API.decode(type: Mastodon.Entity.Token.self, from: data, response: response)
//                return Mastodon.Response.Content(value: value, response: response)
//            }
//            .eraseToAnyPublisher()
//    }
    
}

extension Mastodon.API.OAuth {
    public struct AuthorizeQuery: GetQuery {
        
        public let forceLogin: String?
        public let responseType: String
        public let clientID: String
        public let redirectURI: String
        public let scope: String?
        
        public init(
            forceLogin: String? = nil,
            responseType: String = "code",
            clientID: String,
            redirectURI: String = "urn:ietf:wg:oauth:2.0:oob",
            scope: String? = "read write follow push"
        ) {
            self.forceLogin = forceLogin
            self.responseType = responseType
            self.clientID = clientID
            self.redirectURI = redirectURI
            self.scope = scope
        }
        
        enum CodingKeys: String, CodingKey {
            case forceLogin = "force_login"
            case responseType = "response_type"
            case clientID
            case redirectURI = "redirect_uri"
            case scope
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            forceLogin.flatMap { items.append(URLQueryItem(name: "force_login", value: $0)) }
            items.append(URLQueryItem(name: "response_type", value: responseType))
            items.append(URLQueryItem(name: "clientID", value: clientID))
            items.append(URLQueryItem(name: "redirect_uri", value: redirectURI))
            scope.flatMap { items.append(URLQueryItem(name: "scope", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
    }
}
