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
        public private(set) var accessToken: String
        
        public init(accessToken: String) {
            self.accessToken = accessToken
        }
        
        public mutating func update(accessToken: String) {
            self.accessToken = accessToken
        }
    }

}

extension Mastodon.API.OAuth {
    
    static func authorizeEndpointURL(domain: String) -> URL {
        return Mastodon.API.oauthEndpointURL(domain: domain).appendingPathComponent("authorize")
    }
    static func accessTokenEndpointURL(domain: String) -> URL {
        return Mastodon.API.oauthEndpointURL(domain: domain).appendingPathComponent("token")
    }
    static func revokeTokenEndpointURL(domain: String) -> URL {
        return Mastodon.API.oauthEndpointURL(domain: domain).appendingPathComponent("revoke")
    }
    
    /// Construct user authorize endpoint URL
    ///
    /// This method construct a URL for user authorize
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/1/29
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/oauth/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AuthorizeQuery`
    public static func authorizeURL(
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
    
    /// Obtain User Access Token
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/2
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/oauth/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `AccessTokenQuery`
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func accessToken(
        session: URLSession,
        domain: String,
        query: AccessTokenQuery
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> {
        let request = Mastodon.API.post(
            url: accessTokenEndpointURL(domain: domain),
            query: query,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Token.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }

    /// Revoke User Access Token
    ///
    /// - Since: 0.0.0
    /// - Version: 3.3.0
    /// # Last Update
    ///   2021/2/9
    /// # Reference
    ///   [Document](https://docs.joinmastodon.org/methods/apps/oauth/)
    /// - Parameters:
    ///   - session: `URLSession`
    ///   - domain: Mastodon instance domain. e.g. "example.com"
    ///   - query: `RevokeTokenQuery`
    /// - Returns: `AnyPublisher` contains `Token` nested in the response
    public static func revokeToken(
        session: URLSession,
        domain: String,
        query: RevokeTokenQuery
    ) -> AnyPublisher<Void, Error> {
        let request = Mastodon.API.post(
            url: revokeTokenEndpointURL(domain: domain),
            query: query,
            authorization: nil
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                // `RevokeToken` returns an empty response when success, so just check whether the data type is String to avoid
                _ = try Mastodon.API.decode(type: String.self, from: data, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.OAuth {
    
    public struct AuthorizeQuery: Codable, GetQuery {
        
        public let forceLogin: String?
        public let responseType: String
        public let clientID: String
        public let redirectURI: String
        public let scope: String?
        
        public init(
            forceLogin: String? = nil,
            responseType: String = "code",
            clientID: String,
            redirectURI: String,
            scope: String? = "read write follow push"
        ) {
            self.forceLogin = forceLogin
            self.responseType = responseType
            self.clientID = clientID
            self.redirectURI = redirectURI
            self.scope = scope
        }
        
        var queryItems: [URLQueryItem]? {
            var items: [URLQueryItem] = []
            forceLogin.flatMap { items.append(URLQueryItem(name: "force_login", value: $0)) }
            items.append(URLQueryItem(name: "response_type", value: responseType))
            items.append(URLQueryItem(name: "client_id", value: clientID))
            items.append(URLQueryItem(name: "redirect_uri", value: redirectURI))
            scope.flatMap { items.append(URLQueryItem(name: "scope", value: $0)) }
            guard !items.isEmpty else { return nil }
            return items
        }
        
    }
    
    public struct AccessTokenQuery: Codable, PostQuery {
        public init(
            clientID: String,
            clientSecret: String,
            redirectURI: String,
            scope: String? = "read write follow push",
            code: String?,
            grantType: String
        ) {
            self.clientID = clientID
            self.clientSecret = clientSecret
            self.redirectURI = redirectURI
            self.scope = scope
            self.code = code
            self.grantType = grantType
        }
        
        
        public let clientID: String
        public let clientSecret: String
        public let redirectURI: String
        public let scope: String?
        public let code: String?
        public let grantType: String

        enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case clientSecret = "client_secret"
            case redirectURI = "redirect_uri"
            case scope
            case code
            case grantType = "grant_type"
            
        }
    }

    public struct RevokeTokenQuery: Codable, PostQuery {
        public let clientID: String
        public let clientSecret: String
        public let token: String

        enum CodingKeys: String, CodingKey {
            case clientID = "client_id"
            case clientSecret = "client_secret"
            case token
        }
    }
    
}
