//
//  Mastodon+API+Account.swift
//  
//
//  Created by MainasuK Cirno on 2021/2/2.
//

import Foundation
import Combine

extension Mastodon.API.Account {
    
    static func verifyCredentialsEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts/verify_credentials") 
    }
    static func registerEndpointURL(domain: String) -> URL {
        return Mastodon.API.endpointURL(domain: domain).appendingPathComponent("accounts")
    }
    
    public static func verifyCredentials(
        session: URLSession,
        domain: String,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Account>, Error> {
        let request = Mastodon.API.get(
            url: verifyCredentialsEndpointURL(domain: domain),
            query: nil,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Account.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
    public static func register(
        session: URLSession,
        domain: String,
        query: RegisterQuery,
        authorization: Mastodon.API.OAuth.Authorization
    ) -> AnyPublisher<Mastodon.Response.Content<Mastodon.Entity.Token>, Error> {
        let request = Mastodon.API.post(
            url: registerEndpointURL(domain: domain),
            query: query,
            authorization: authorization
        )
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                let value = try Mastodon.API.decode(type: Mastodon.Entity.Token.self, from: data, response: response)
                return Mastodon.Response.Content(value: value, response: response)
            }
            .eraseToAnyPublisher()
    }
    
}

extension Mastodon.API.Account {
    
    public struct RegisterQuery: Codable, PostQuery {
        public let reason: String?
        public let username: String
        public let email: String
        public let password: String
        public let agreement: Bool
        public let locale: String
        
        public init(reason: String? = nil, username: String, email: String, password: String, agreement: Bool, locale: String) {
            self.reason = reason
            self.username = username
            self.email = email
            self.password = password
            self.agreement = agreement
            self.locale = locale
        }
        
        var body: Data? {
            return try? Mastodon.API.encoder.encode(self)
        }
    }
    
}
